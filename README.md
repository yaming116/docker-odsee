

下载地址
链接： https://edelivery.oracle.com/osdc/faces/SoftwareDelivery

搜索关键字： Oracle Directory Server Enterprise Edition

下载完成之后 sun-dsee7.zip 文件放置在当前文件夹内，太大了上传不了

构建文档参考： https://github.com/oehrlis/docker/blob/master/OracleODSEE/README.md

```bash
docker build -t oracle/odsee:11.1.1.7.0 .
```


```bash
docker run -d --name odsee \
--hostname odsee -p 8080:8080 -p 10389:1389  \
-e ODSEE_INSTANCE=master \
--volume $PWD/u01:/u01 \
--volume $PWD/scripts:/u01/scripts \
oracle/odsee:11.1.1.7.0
```