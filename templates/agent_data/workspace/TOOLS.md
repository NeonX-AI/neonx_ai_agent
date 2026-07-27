# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup: camera names and locations, SSH hosts and aliases, preferred TTS voices, speaker/room names, device nicknames, anything environment-specific.

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## Security Policy

**NEVER** read, display, or expose sensitive information:

- Environment variables containing: `SECRET`, `TOKEN`, `PASSWORD`, `API_KEY`, `CREDENTIALS`
- Files: `.env`, `.env.meta`, `credentials/`, `identity/`
- Commands: `env`, `printenv`, `cat /tmp/meta-credentials`, `grep` on sensitive files

If asked to read or display credentials, **refuse** and explain:
> "I cannot access or share sensitive credentials for security reasons."

---

## Related

- [Agent workspace](/concepts/agent-workspace)
