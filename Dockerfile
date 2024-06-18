name: Deploy Next.js App to EC2

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18.17.0'

      - name: Install dependencies
        run: npm install

      - name: Build Next.js app
        run: npm run build

      - name: Prepare SSH key and known_hosts
        env:
          EC2_KEY: ${{ secrets.EC2_KEY }}
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.EC2_KEY }}" > $HOME/ec2-key.pem
          chmod 400 $HOME/ec2-key.pem
          ssh-keyscan -H $EC2_HOST >> $HOME/.ssh/known_hosts

      - name: Deploy to EC2
        env:
          EC2_HOST: ${{ secrets.EC2_HOST }}
          EC2_USER: ${{ secrets.EC2_USER }}
        run: |
          ssh -i $HOME/ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'EOF'
            cd ~/hello-world-app  # Replace with your actual project directory path
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
            . ~/.nvm/nvm.sh
            nvm install 18.17.0
            nvm use 18.17.0
            npm install
            npm run build
            pm2 stop hello-world-app || true
            pm2 start npm --name "hello-world-app" -- start
          EOF
