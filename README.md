# What is this? 
 
It is container, which provides nginx based https/ssl proxy. It uses https://letsencrypt.org/ and https://github.com/xenolf/lego to automatically obtain and renew certificates. 
 
It is mainly intended for use with internal (not publicly accessible) services, such as internal Docker registries, so it uses DNS challenge and API enabled DNS servers. 
 
# Configuration 
 
Is done using environmental variables 
 
name|description 
--- | --- 
`DOMAIN` | Domain name for certificate generation 
`EMAIL` | Email for certificate generation 
`DNS_PROVIDER` | Lego dns provider - see https://github.com/xenolf/lego/tree/master/providers/dns 
`UPSTREAM_SERVER` | Upstream server address 
`LEGO_SERVER` | (optional) Address to Let’s Encrypt server, defaults to https://acme-v01.api.letsencrypt.org/directory 
`RENEW_DAYS` | (optional) Number of days left for certificate validity before it is renewed, default to 30 
 
DNS challenge providers are also configured through environmental variables, see https://github.com/xenolf/lego for details 
 
# Examples

## Simple docker instance with external service and route53 provider 

``` 
docker run --name nginx-lego \ 
  -p 8443:443 \ 
  -e DOMAIN=some.example.com \ 
  -e EMAIL=email@example.com \ 
  -e DNS_PROVIDER=route53 \ 
  -e AWS_REGION=eu-central-1 \ 
  -e AWS_ACCESS_KEY_ID=XXX \ 
  -e AWS_SECRET_ACCESS_KEY=YYY \ 
  -e UPSTREAM_SERVER=192.168.1.1 \ 
  -v /var/lego-test:/var/lego \ 
  -t \ 
  nginx-lego 
``` 
 
## Kubernetes replication controller + service for internal docker registry 

```yaml 
kind: ReplicationController 
apiVersion: v1 
metadata: 
  name: docker-registry 
  namespace: kube-system 
spec: 
  replicas: 1 
  selector: 
    name: docker-registry 
    role: docker-registry 
  template: 
    spec: 
      containers: 
      - name: registry 
        image: registry:2 
        volumeMounts: 
          - mountPath: /var/lib/registry 
            subPath: registry 
            name: docker-registry 
        ports: 
        - containerPort: 5000 
      - name: proxy 
        image: pavelsor/nginx-lego 
        env: 
          - name: DOMAIN 
            value: registry.example.com 
          - name: EMAIL 
            value: email@example.com 
          - name: DNS_PROVIDER 
            value: route53 
          - name: AWS_REGION 
            value: eu-central-1 
          - name: AWS_ACCESS_KEY_ID 
            value: XXX 
          - name: AWS_SECRET_ACCESS_KEY 
            value: YYY 
          - name: UPSTREAM_SERVER 
            value: 127.0.0.1:5000 
        volumeMounts: 
          - mountPath: /var/lego 
            subPath: lego 
            name: docker-registry 
        ports: 
        - containerPort: 443 
      volumes: 
      - name: docker-registry 
        emptyDir: {}     
    metadata: 
      labels: 
        name: docker-registry 
        run: docker-registry 
        role: docker-registry 
--- 
kind: Service 
apiVersion: v1 
metadata: 
  name: docker-registry 
  namespace: kube-system 
spec: 
  selector: 
    run: docker-registry 
  ports: 
  - protocol: TCP 
    name: main 
    port: 443 
    targetPort: 443 
```