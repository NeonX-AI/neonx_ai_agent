import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

const DEFAULT_WORKSPACE = "/home/node/.openclaw/workspace";
const MAX_OUTPUT_CHARS = 60_000;
const MAX_DIAGNOSTIC_CHARS = 12_000;
const WORKER_TIMEOUT_MS = 180_000;

interface WorkerParams {
  task: string;
  workspace?: string;
}

function resolveWorkspace(value?: string): string {
  const workspace = resolve(value?.trim() || DEFAULT_WORKSPACE);
  const allowedRoots = [
    resolve("/home/node/.openclaw/workspace"),
    resolve("/home/node/.openclaw/projects"),
  ];
  if (!allowedRoots.some((root) => workspace === root || workspace.startsWith(`${root}/`))) {
    throw new Error("Workspace must be inside the OpenClaw workspace or projects directory.");
  }
  return workspace;
}

export default definePluginEntry({
  id: "openclaw-message-listener",
  name: "OpenClaw Message Listener",
  description: "Provides message monitoring and an internal Codex worker for every chat channel",

  register(api: any) {
    api.registerTool({
      name: "codex_worker",
      description: "Delegate a coding, CAD, Fusion 360, or AutoCAD task to Codex inside the container. Use this whenever the user explicitly asks to use Codex. No conversation binding is required.",
      parameters: {
        type: "object",
        additionalProperties: false,
        required: ["task"],
        properties: {
          task: { type: "string", minLength: 1, maxLength: 20_000 },
          workspace: { type: "string", description: "Optional directory under /home/node/.openclaw/workspace or /home/node/.openclaw/projects." },
        },
      },
      async execute(_id: string, params: WorkerParams) {
        const workspace = resolveWorkspace(params.workspace);
        const tempDir = await mkdtemp(join(tmpdir(), "openclaw-codex-worker-"));
        const outputFile = join(tempDir, "last-message.txt");
        const args = [
          "exec",
          "--skip-git-repo-check",
          "--sandbox", "danger-full-access",
          "--output-last-message", outputFile,
          "--cd", workspace,
          "-",
        ];
        let stderr = "";

        try {
          await new Promise<void>((resolveProcess, rejectProcess) => {
            const child = spawn("codex", args, {
              cwd: workspace,
              detached: process.platform !== "win32",
              stdio: ["pipe", "ignore", "pipe"],
              env: { ...process.env, CODEX_HOME: process.env.CODEX_HOME || "/root/.codex" },
            });
            const timer = setTimeout(() => {
              if (child.pid && process.platform !== "win32") {
                try { process.kill(-child.pid, "SIGKILL"); } catch { child.kill("SIGKILL"); }
              } else {
                child.kill("SIGKILL");
              }
              rejectProcess(new Error("Codex exceeded the 3-minute worker timeout."));
            }, WORKER_TIMEOUT_MS);
            child.stderr.setEncoding("utf8");
            child.stderr.on("data", (chunk: string) => {
              stderr = (stderr + chunk).slice(-MAX_DIAGNOSTIC_CHARS);
            });
            child.once("error", (error) => {
              clearTimeout(timer);
              rejectProcess(error);
            });
            child.once("close", (code) => {
              clearTimeout(timer);
              code === 0 ? resolveProcess() : rejectProcess(new Error(`Codex exited with code ${code}.\n${stderr}`));
            });
            child.stdin.end(params.task.trim(), "utf8");
          });
          const answer = (await readFile(outputFile, "utf8")).trim();
          const text = answer || stderr.trim() || "Codex completed without a text response.";
          return { content: [{ type: "text", text: text.slice(0, MAX_OUTPUT_CHARS) }] };
        } catch (error: any) {
          const detail = [error?.message, stderr].filter(Boolean).join("\n");
          return { content: [{ type: "text", text: `Codex worker failed:\n${detail.slice(0, MAX_DIAGNOSTIC_CHARS)}` }], isError: true };
        } finally {
          await rm(tempDir, { recursive: true, force: true });
        }
      },
    });
  },
});
