# Overview

Essentially what happens is:
1. Our dockerfile has ubi 9 and the openshift command line, as well as some other utilities like gzip and wget. You can addpackages to microdnf on the first line of the RUN line 
    ```
    RUN microdnf update && microdnf install -y tar gzip < ADD PACKAGE HERE > wget && \
    ...
    ```

2. Copy in out script files, chmod them so they can be executed. 

3. Execute a startup command. 

4. The services that will be configured are passed in as an env variable (comma separated)

5. A switch statement calls the relevant config function (we put the api calls etc here)

Currently the debug output in the cluster gives: 
```
started post deploy config

performing post deploy tasks for ZEN,IER,IER-TM,TM

Configuring Zen
Configuring IER
Configuring IER-TM
Configuring TM

```

Ultimately we should be able to put our configuration methods in the correct place and all the configuration should happen. 