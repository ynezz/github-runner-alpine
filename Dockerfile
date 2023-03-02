FROM alpine:3.17 as base

ENV USER=runner
ENV HOME=/home/runner
ENV GITHUB_WORKSPACE=/home/runner/workspace
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN apk add --no-cache \
	bash \
	curl \
    	ca-certificates \
	git \
	icu-libs \
	jq \
	krb5-libs \
	libgcc \
	libintl \
	libssl1.1 \
	libstdc++ \
	sudo \
	zlib

RUN mkdir -p /home/runner/workspace
RUN adduser \
	--disabled-password \
	--home "${HOME}" \
	--uid "1000" \
	"$USER" && \
	chown -R "$USER:$USER" /home/runner
RUN addgroup "$USER" wheel
RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-without-password



FROM base as build
ARG RUNNER_VERSION
WORKDIR /home/runner
USER $USER
RUN git clone \
	--depth=1 \
	--branch "v$RUNNER_VERSION" \
	https://github.com/actions/runner.git
COPY --chown=runner:runner 0001-linux-musl-x64-runtime-support.patch runner/
RUN cd runner && git apply 0001-linux-musl-x64-runtime-support.patch
RUN cd runner/src && ./dev.sh layout Release linux-musl-x64



FROM base as runner
USER $USER
WORKDIR /home/runner
COPY --chown=runner:runner --from=build /home/runner/runner/_layout/. /home/runner/
COPY --chown=runner:runner entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]
