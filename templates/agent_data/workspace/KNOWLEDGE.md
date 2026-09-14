# Knowledge Base

**INSTRUCTIONS FOR AGENT**: This file contains a list of available skills and knowledge. When the user requests a specific task:
1. Check the skills list below
2. If a matching skill exists → Read `skills/<skill-name>/SKILL.md` before proceeding
3. Follow the instructions in the skill file (connection, API, pitfalls, etc.)

## Skills (Special Capabilities)

**IMPORTANT**: Always check this list before performing any task.

### How to Use Skills:

1. **When user requests a task**: Check the skills list above
2. **If a matching skill exists**: Read `skills/<skill-name>/SKILL.md` before proceeding
3. **Follow the instructions**: The skill will show how to connect, use APIs, and avoid pitfalls

## How to Use

When user asks about a tool/API/integration:

1. Check if a corresponding skill exists in the list above
2. If yes → Read `skills/<skill-name>/SKILL.md`
3. If no → Check `instructions/` for information
4. Apply the knowledge to answer or perform the task

## Adding New Knowledge

To add new knowledge:

1. Create a `.md` file in `default-knowledge/instructions/` (on host)
2. Run `./update-clients.sh` or `./sync-knowledge.sh`
3. The file will be copied to `agent_data/instructions/` of all clients
