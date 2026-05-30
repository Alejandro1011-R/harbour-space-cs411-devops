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
                sh 'scp main laborant@target:~'
            }
        }
    }
}