pipeline {
   agent {
       kubernetes {
           label 'docker-agent'
           defaultContainer 'docker'
       }
   }

   environment {
       REGISTRY = 'harbor.jdevops.co.kr'
       HARBOR_PROJECT = 'test'
       IMAGE_NAME = 'test-nginx'
       DOCKER_IMAGE = "${REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"
       DOCKER_CREDENTIALS_ID = 'harbor-credentials'
       SONAR_TOKEN = credentials("sonarqube-credentials")
   }

   stages {
       stage('Checkout') {
           steps {
               checkout scm
           }
       }

       stage('SonarQube Analysis') {
           steps {
               container('sonar-scanner') {
                   withSonarQubeEnv('sonarqube') {
                       sh """
                        sonar-scanner \\
                        -Dsonar.projectKey=test-nginx \\
                        -Dsonar.projectName=test-nginx \\
                        -Dsonar.sources=. \\
                        -Dsonar.exclusions=**/node_modules/** \\
                        -Dsonar.login=${SONAR_TOKEN}
                       """
                   }
               }
           }
       }

       stage('Docker Build') {
           steps {
               script {
                   timeout(time: 2, unit: 'MINUTES') {
                       sh '''#!/bin/sh
                           until docker info >/dev/null 2>&1; do
                               echo "Waiting for docker daemon..."
                               sleep 2
                           done
                       '''
                   }

                   sh """
                       docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                   """
               }
           }
       }

       stage('Docker Push') {
           steps {
               script {
                   withDockerRegistry([credentialsId: DOCKER_CREDENTIALS_ID, url: "https://${REGISTRY}"]) {
                       sh """
                           docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                       """
                   }
               }
           }
       }
   }

   post {
       success {
           echo 'Successfully built and pushed the image!'
       }
       failure {
           echo 'Failed to build or push the image'
       }
       always {
           script {
               try {
                   sh """
                       docker rmi ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
                   """
               } catch (Exception e) {
                   echo "Failed to remove docker image: ${e.message}"
               }
           }
       }
   }
}