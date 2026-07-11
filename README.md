git clone https://github.com/NeonX-AI/neonx_ai_agent.git
cd neonx_ai_agent
docker compose up -d --build
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw config => Model => http://9router:20128/v1
nano /root/.openclaw/openclaw.json