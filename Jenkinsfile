pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)

        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
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

                    required_keys="MARIADB_ROOT_PASSWORD MARIADB_PASSWORD POSTGRES_PASSWORD OPENAI_API_KEY SMS_KEY SECRET_KEY PHONE TMDB_API_KEY JWT_KEY TOSS_SECRET_KEY TOSS_WIDGET_SECRET_KEY"
                    for key in $required_keys
                    do
                        if ! grep -q "^${key}=." .env
                        then
                            echo "필수 환경변수 누락: ${key}"
                            exit 1
                        fi
                    done

                    docker compose \
                        --project-name deploy \
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

        stage('Verify external HTTPS') {
            steps {
                sh '''
                    set -eu

                    echo "외부 HTTPS 접속을 확인합니다."

                    curl \
                        --fail \
                        --silent \
                        --show-error \
                        --location \
                        --retry 10 \
                        --retry-delay 3 \
                        --retry-all-errors \
                        --output /dev/null \
                        https://kiosk.hyeyum.it.kr/

                    curl \
                        --fail \
                        --silent \
                        --show-error \
                        --location \
                        --retry 5 \
                        --retry-delay 2 \
                        --retry-all-errors \
                        --output /dev/null \
                        https://kiosk.hyeyum.it.kr/admin/login

                    curl \
                        --fail \
                        --silent \
                        --show-error \
                        --location \
                        --retry 5 \
                        --retry-delay 2 \
                        --retry-all-errors \
                        --output /dev/null \
                        https://kiosk.hyeyum.it.kr/swagger-ui/index.html

                    echo "외부 HTTPS 응답 확인 완료"
                '''
            }
        }
    }

    post {
        failure {
            script {
                sh(
                    returnStatus: true,
                    script: '''
                        echo "배포 실패 진단을 시작합니다."

                        docker ps -a \
                            --filter name=kiosk- \
                            --format 'table {{.Names}}\\t{{.Status}}'

                        if [ -f .env ] &&
                           [ -f backend/deploy/compose.yml ]
                        then
                            docker compose \
                                --project-name deploy \
                                --env-file .env \
                                -f backend/deploy/compose.yml \
                                ps

                            docker compose \
                                --project-name deploy \
                                --env-file .env \
                                -f backend/deploy/compose.yml \
                                logs \
                                --no-color \
                                --tail=200 \
                                kiosk-backend \
                                kiosk-mariadb \
                                kiosk-postgres \
                                kiosk-view
                        else
                            echo "Compose 파일 또는 .env가 없어 상세 로그를 생략합니다."
                        fi
                    '''
                )
            }
        }

        always {
            sh '''
                rm -f .env
            '''
        }
    }
}
