Build and run locally:

```
git clone https://github.com/mathieu-benoit/myblog
git submodule init
git submodule update
sudo docker build -t blog .
sudo docker run -d -p 8080:8080 blog
```
