# 后端镜像。**构建上下文必须是仓库根目录**（见 docker-compose.yml 的 context: ..）
# 因为要 COPY juling-server/target/juling-server.jar，而 jar 里已含全部模块。
FROM eclipse-temurin:21-jre

RUN mkdir -p /juling-server /juling-server/heap /juling-server/uploads
WORKDIR /juling-server

# 本镜像**只打包、不编译** —— 编译请在宿主机或 CI 上先跑：
#     mvn -T 1C clean package -DskipTests
# 这样镜像里不需要 Maven 和整个源码树：构建快、体积小、可复现。
COPY juling-server/target/juling-server.jar app.jar

ENV TZ=Asia/Shanghai
ENV JAVA_OPTS="-Xms512m -Xmx512m -Djava.security.egd=file:/dev/./urandom"
ENV ARGS=""
EXPOSE 48080

# 健康检查走 actuator（与 script/shell/deploy.sh 里的探活地址一致）
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=5 \
  CMD wget -qO- http://127.0.0.1:48080/actuator/health/ >/dev/null 2>&1 || exit 1

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar $ARGS"]
