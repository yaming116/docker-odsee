

docker run -d --name odsee \
--hostname odsee -p 8080:8080 -p 10389:1389  \
-e ODSEE_INSTANCE=master \
--volume $PWD/u01:/u01 \
--volume $PWD/scripts:/u01/scripts \
oracle/odsee:11.1.1.7.0
