// Jenkins 파이프라인의 시작을 선언합니다.
pipeline {
    // Kubernetes 에이전트를 설정합니다.
    agent {
        kubernetes {
            // 'docker-agent' 라벨을 가진 Pod을 생성합니다.
            label 'docker-agent'
            // 기본 컨테이너를 'docker'로 지정합니다.
            defaultContainer 'docker'
        }
    }

    // 파이프라인에서 사용할 환경 변수들을 정의합니다.
    environment {
        // Harbor 레지스트리 관련 설정입니다.
        // 수정해주세요
        REGISTRY = 'harbor.jbnu.ac.kr'
        HARBOR_PROJECT = '<사용자명 입력>'
        IMAGE_NAME = '<이미지이름 입력>'
        // 도커 이미지의 전체 경로를 설정합니다.
        DOCKER_IMAGE = "${REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"
        // Harbor 인증 정보의 ID를 설정합니다.
        DOCKER_CREDENTIALS_ID = 'harbor-credentials'
        // SonarQube 인증 토큰을 Jenkins 크레덴셜에서 가져옵니다.
        SONAR_TOKEN = credentials("sonarqube-credentials")
    }

    // 파이프라인의 각 단계를 정의합니다.
    stages {
        // 소스 코드를 체크아웃하는 단계입니다.
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // SonarQube를 사용하여 코드 품질을 분석하는 단계입니다.
        stage('SonarQube Analysis') {
            steps {
                // sonar-scanner 컨테이너에서 실행합니다.
                container('sonar-scanner') {
                    // SonarQube 환경 설정을 적용합니다.
                    withSonarQubeEnv('sonarqube') {
                        // sonar-scanner 명령어를 실행하여 코드 분석을 수행합니다.
                        // 수정해주세요
                        sh """
                         sonar-scanner \\
                         -Dsonar.projectKey=<사용자명-서비스명> \\
                         -Dsonar.projectName=<사용자명-서비스명> \\
                         -Dsonar.sources=. \\
                         -Dsonar.exclusions=**/node_modules/** \\
                         -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        // 도커 이미지를 빌드하는 단계입니다.
        stage('Docker Build') {
            steps {
                script {
                    // 도커 데몬이 준비될 때까지 최대 2분간 대기합니다.
                    timeout(time: 2, unit: 'MINUTES') {
                        sh '''#!/bin/sh
                            until docker info >/dev/null 2>&1; do
                                echo "Waiting for docker daemon..."
                                sleep 2
                            done
                        '''
                    }

                    // 도커 이미지를 빌드합니다.
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    """
                }
            }
        }

        // 빌드된 도커 이미지를 Harbor 레지스트리에 푸시하는 단계입니다.
        stage('Docker Push') {
            steps {
                script {
                    // Harbor 레지스트리 인증 정보를 사용하여 이미지를 푸시합니다.
                    withDockerRegistry([credentialsId: DOCKER_CREDENTIALS_ID, url: "https://${REGISTRY}"]) {
                        sh """
                            docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
    }

    // 파이프라인 실행 후 수행할 작업들을 정의합니다.
    post {
        // 파이프라인이 성공적으로 완료된 경우
        success {
            echo 'Successfully built and pushed the image!'
        }
        // 파이프라인이 실패한 경우
        failure {
            echo 'Failed to build or push the image'
        }
        // 성공/실패 여부와 관계없이 항상 실행
        always {
            script {
                try {
                    // 로컬에 있는 도커 이미지를 제거합니다.
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
