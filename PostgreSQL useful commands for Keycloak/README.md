# Useful commands using for retrieving info about Keycloak

This was implemented into an Openshift environment.

Via command line interface: 

```
$ oc project openshift-sso
$ oc exec keycloak-postgresql-<*> -- psql root -c '<COMMANDS>'
```

Via web-console: Project → openshift-sso, Pods → keycloak-postgresql-<*> → Terminal

```
$ psql root
root=# <COMMANDS>
```

Useful commands to apply
```
root=# \dn                        # list schemas
root=# \dt                        # list tables, by default schema public.
root=# select name from realm;    # list the REALM implemented into Keycloak
       name       
-------------------
 sandbox
 master
(2 rows)
 
# next query will return the data of users, encrypted passwords, mails
# table credential: where credentials are stored
# table user_entity: information about users
# table realm: Realms used by keycloak
root=# select r.name as RealmName, u.username, u.email, c.secret_data, c.credential_data
root-# from credential c                                                                                 
root-# inner join user_entity u on u.id=c.user_id                                      
root-# inner join realm r on r.id=u.realm_id;
     RealmName     |      username       |             email              |                       secret_data                      |                          credential_data
-------------------+---------------------+--------------------------------+----------------------------------------------------------------------------------------------------------------------------
 master            | admin               |                                | {"value":"***","salt":"***","additionalParameters":{}} | {"hashIterations":***,"algorithm":"***","additionalParameters":{}}
 ```