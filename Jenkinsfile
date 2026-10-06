pipeline {
    agent any

    stages {
        stage('SSH Test') {
            steps {
                sshagent(['ubuntu']) {
                    sh 'ssh -o StrictHostKeyChecking=no ubuntu@192.168.88.30 hostname'
                }
            }
        }

        stage('Deploy Clothing Application') {
            steps {
                sshagent(['ubuntu']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@192.168.88.30 '
                            set -e
                            cd /opt/docker-hosting/applications/clothing

                            echo "===== Reset local uncommitted changes ====="
                            git reset --hard HEAD
                            git clean -fd

                            echo "===== Pull latest code ====="
                            git pull --ff-only origin main

                            echo "===== Build Docker images ====="
                            docker compose build

                            echo "===== Start containers ====="
                            docker compose up -d

                            echo "===== Container status ====="
                            docker compose ps

                            echo "===== Backend logs ====="
                            docker compose logs --tail=30 backend
                            
                            echo "===== Test Nginx configuration ====="
                            docker exec docker-gateway nginx -t

                            echo "===== Reload Nginx ====="
                            docker exec docker-gateway nginx -s reload

                            echo "===== Deployment completed ====="
                        '
                    '''
                }
            }
        }
    }
    post {
        failure {
            echo 'CLOTHING APPLICATION DEPLOYMENT FAILED'
        }
    }
}
