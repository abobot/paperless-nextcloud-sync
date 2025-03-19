FROM ubuntu:latest

# 更新系统并安装依赖（使用 --no-install-recommends 以减少镜像大小）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        davfs2 \
        ca-certificates \
        locales \
        inotify-tools \
        tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置默认语言环境
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:de
ENV LC_ALL=en_US.UTF-8
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# 声明 WebDAV 及本地同步目录
VOLUME [ "/mnt/source", "/mnt/webdrive" ]

# 复制脚本
COPY *.sh /

# 入口点：使用 tini 处理信号
ENTRYPOINT [ "tini", "-g", "--", "/start.sh" ]

# 健康检查
HEALTHCHECK --timeout=10s --start-period=10s CMD bash /healthcheck.sh || exit 1

# 构建命令：
# docker build --file ./paperless-nextcloud-sync.Dockerfile --tag paperless-nextcloud-sync .
