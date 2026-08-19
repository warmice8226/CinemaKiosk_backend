pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Clean workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout repositories') {
            steps {
                dir('backend') {
                    git branch: 'main',
                        url: 'https://github.com/warmice8226/CinemaKiosk_backend.git'
                }

                dir('view') {
                    git branch: 'dev',
                        url: 'https://github.com/warmice8226/CinemaKiosk_view.git'
                }
            }
        }

        stage('Prepare environment') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'cinema-kiosk-env',
                        variable: 'KIOSK_ENV'
                    )
                ]) {
                    sh '''
                        set -eu

                        cp "$KIOSK_ENV" .env
                        chmod 600 .env
                        test -s .env

                        echo ".env 파일 준비 완료"
                    '''
                }
            }
        }

        stage('Validate compose') {
            steps {
                sh '''
                    set -eu

                    docker compose \
                        --env-file .env \
                        -f backend/deploy/compose.yml \
                        config --quiet

                    echo "Docker Compose 설정이 정상입니다."
                '''
            }
        }
        
                stage('Build and deploy') {
            steps {
                sh '''
                    set -eu

                    docker compose \
                        --project-name deploy \
                        --env-file .env \
                        -f backend/deploy/compose.yml \
                        up -d --build --remove-orphans

                    echo "컨테이너 빌드 및 배포 명령 완료"
                '''
            }
        }

        stage('Verify deployment') {
            steps {
                sh '''
                    set -eu

                    echo "컨테이너 상태:"
                    docker compose \
                        --project-name deploy \
                        --env-file .env \
                        -f backend/deploy/compose.yml \
                        ps

                    for container in \
                        kiosk-mariadb \
                        kiosk-postgres \
                        kiosk-backend \
                        kiosk-view
                    do
                        state="$(docker inspect \
                            --format '{{.State.Status}}' \
                            "$container")"

                        if [ "$state" != "running" ]; then
                            echo "$container 상태 이상: $state"
                            exit 1
                        fi
                    done

                    echo "데이터베이스가 healthy 상태가 될 때까지 대기합니다."

                    for container in kiosk-mariadb kiosk-postgres
                    do
                        count=0

                        while [ "$(docker inspect \
                            --format '{{.State.Health.Status}}' \
                            "$container")" != "healthy" ]
                        do
                            count=$((count + 1))

                            if [ "$count" -ge 30 ]; then
                                echo "$container health check 시간 초과"
                                exit 1
                            fi

                            sleep 2
                        done
                    done

                    echo "백엔드 시작을 확인합니다."

                    count=0
                    until docker exec portfolio-caddy \
                        wget -qO- \
                        http://kiosk-backend:8080/swagger-ui/index.html \
                        > /dev/null
                    do
                        count=$((count + 1))

                        if [ "$count" -ge 30 ]; then
                            echo "백엔드 응답 확인 시간 초과"
                            exit 1
                        fi

                        sleep 2
                    done

                    docker exec portfolio-caddy \
                        wget -qO- http://kiosk-view:80 \
                        > /dev/null

                    echo "키오스크 배포 및 내부 응답 확인 완료"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                rm -f .env
            '''
        }
    }
}
