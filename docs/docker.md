## Build the container

```
git clone --recurse-submodules https://github.com/mathieu-benoit/mathieu-benoit.github.io
cd myblog
docker build -t myblog .
```

## Run locally

```
docker run -d \
    -p 80:8080 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    myblog
```
