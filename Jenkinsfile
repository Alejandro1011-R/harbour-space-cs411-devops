pipeline {
    agent any
    environment {
        CGO_ENABLED = '0'
    }
    tools {
       go "1.24.1"
    }

    stages {
        stage('Build') {
            steps {
                sh "go build main.go"
            }
        }
        stage('Deploy') {
            steps {
                sh 'mkdir -p ~/.ssh'
                sh 'ssh-keyscan -H target >> ~/.ssh/known_hosts'
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'target-ssh',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh 'scp -i $SSH_KEY main laborant@target:~'
                }
            }
        }

    }
}