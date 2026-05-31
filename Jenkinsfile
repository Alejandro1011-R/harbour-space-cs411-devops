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
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'target-ssh',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh 'ansible-playbook -i hosts.ini --private-key=$SSH_KEY playbook.yml'
                }
            }
        }

    }
}