FROM mcr.microsoft.com/dotnet/sdk:7.0@sha256:f712881bafadf0e56250ece1da28ba2baedd03fb3dd49a67f209f9d0cf928e81 as builder
WORKDIR /app
COPY my-sample-app.csproj .
RUN dotnet restore my-sample-app.csproj -r linux-musl-x64
COPY . .
RUN dotnet publish my-sample-app.csproj -r linux-musl-x64 -c release -o /my-sample-app --no-restore --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=partial

FROM mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64@sha256:941c0748b773dd13f2930cded91d01f62d357a785550c25eabe3d53d7997ae4b as slim
RUN apk del wget

FROM slim
WORKDIR /app
COPY --from=builder /my-sample-app .
EXPOSE 7070
ENV ASPNETCORE_URLS=http://*:7070
ENV DOTNET_EnableDiagnostics=0
USER 1000
ENTRYPOINT ["/app/my-sample-app"]
