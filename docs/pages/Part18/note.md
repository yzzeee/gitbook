# 18. 모듈

리소스를 모아놓은 것들<br/>
* 루트 모듈
* 자식 모듈

```tf
module "consul" {
  source = "hashicorp/consul/aws"
  version = "0.0.5"

  servers = 3
}
```

* 모듈의 소스 유형
모듈은 어디서 가져올 수 있을까?
- 로컬 경로
- 테라폼 레지스트리
- Github
- BitBucket
- Generic Git, Mercurial repositories
- HTTP URL
- S3 bucket
- GCS buckets 등등

https://registry.terraform.io/

* 테라폼 상태 정보 리스팅
```shell
terraform state list
```