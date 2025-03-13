// Jenkins 파이프라인의 시작을 선언합니다.
pipeline {
    // Kubernetes 에이전트를 설정합니다.
    agent {
        kubernetes {
            // 'kaniko-agent' 라벨을 가진 Pod을 생성합니다.
            label 'kaniko-agent'
            // 기본 컨테이너를 'kaniko'로 지정합니다.
            defaultContainer 'kaniko'
        }
    }

    // 파이프라인에서 사용할 환경 변수들을 정의합니다.
    environment {
        // Harbor 레지스트리 관련 설정입니다.
        // 수정해주세요
        REGISTRY = 'harbor.jbnu.ac.kr'
        HARBOR_PROJECT = '<사용자 이름>'
        IMAGE_NAME = '<이미지 이름>'
        DOCKER_IMAGE = "${REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"
        DOCKER_CREDENTIALS_ID = 'harbor-credentials'
        SONAR_TOKEN = credentials("sonarqube-credentials")
        HARBOR_CREDENTIALS = credentials("${DOCKER_CREDENTIALS_ID}")
    }

    // 파이프라인의 각 단계를 정의합니다.
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // SonarQube를 사용하여 코드 품질을 분석하는 단계입니다.
        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withSonarQubeEnv('sonarqube') {
                        // sonar-scanner 명령어를 실행하여 코드 분석을 수행합니다.
                        sh """
                            sonar-scanner \\
                            -Dsonar.projectKey=${HARBOR_PROJECT}-${IMAGE_NAME} \\
                            -Dsonar.projectName=${HARBOR_PROJECT}-${IMAGE_NAME} \\
                            -Dsonar.sources=. \\
                            -Dsonar.exclusions=**/node_modules/** \\
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        // Docker 설정 파일 생성
        stage('Create Docker Config') {
            steps {
                script {
                    // Kaniko가 사용할 Docker 설정 파일 생성
                    sh """
                        mkdir -p /home/jenkins/agent/.docker
                        echo '{"auths":{"${REGISTRY}":{"username":"${HARBOR_CREDENTIALS_USR}","password":"${HARBOR_CREDENTIALS_PSW}"}}}' > /home/jenkins/agent/.docker/config.json
                        cat /home/jenkins/agent/.docker/config.json
                        cp /home/jenkins/agent/.docker/config.json /home/jenkins/agent/config.json
                    """
                    
                    // Kaniko가 사용할 볼륨에 Docker 설정 파일 복사
                    container('kaniko') {
                        sh """
                            mkdir -p /kaniko/.docker
                            cp /home/jenkins/agent/config.json /kaniko/.docker/config.json
                            ls -la /kaniko/.docker
                        """
                    }
                }
            }
        }

        // Kaniko를 사용하여 도커 이미지를 빌드하고 푸시하는 단계입니다.
        stage('Build and Push with Kaniko') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \\
                        --context=\$(pwd) \\
                        --destination=${DOCKER_IMAGE}:${BUILD_NUMBER} \\
                        --cleanup
                    """
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
            deleteDir()
            echo "Cleaning up pod resources"
        }
    }
}
