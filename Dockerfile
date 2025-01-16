# Nginx 이미지를 기본 이미지로 사용
FROM nginx:latest

# Nginx의 기본 경로에 HTML 파일 복사
COPY ./index.html /usr/share/nginx/html/index.html

# Nginx 기본 포트
EXPOSE 80

# 컨테이너 실행 시 Nginx 시작
CMD ["nginx", "-g", "daemon off;"]
