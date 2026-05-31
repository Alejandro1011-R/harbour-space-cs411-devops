pipeline {
    agent any 
    environment {
        IMAGE_NAME = "ttl.sh/alejandro-ramirez:2h" 
    }
    stages {
        stage('Build and Push Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
                sh "docker push ${IMAGE_NAME}"
            }
        }
        stage('Deploy to Docker VM') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'docker-ssh', keyFileVariable: 'SSH_KEY')]) {
                    sh "ssh -i $SSH_KEY laborant@docker 'docker rm -f my-go-app || true'"
                    sh "ssh -i $SSH_KEY laborant@docker 'docker run -d -p 4444:4444 --name my-go-app ${IMAGE_NAME}'"
                }
            }
        }
    }
}