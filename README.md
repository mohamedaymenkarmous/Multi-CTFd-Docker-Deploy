# Multi-CTFd-Docker-Deploy
Repository to deploy multiple CTFd instances using docker.

This project is based on the [CTFd platform](https://github.com/CTFd/CTFd). You can create multiple CTFd instances hosted on the same server automatically.

## Configuration

You need to rename [config.json.example](config.json.example) as `config.json` and then you edit the renamed file.

### Example

This is an example of a configuration that will let you create three CTFd instances (one instance published over HTTP and two instances published over HTTPS) and generate 2 TLS certificates:

```
{
  "projects":
  [
    {
      "name":"ctf-entry-level",
      "target":"ctfd-ctf-entry-level-container",
      "internal-port":"8000",
      "description":"A CTF with an entry level",
      "hostname":"entry.ctf.example.com",
      "generic-hostname":"",
      "default-server":"0",
      "deferred-server":"0",
      "tls-enabled":"0"
    },
    {
      "name":"ctf-medium-level",
      "target":"ctfd-ctf-medium-level-container",
      "internal-port":"8000",
      "description":"A CTF with a medium level",
      "hostname":"medium.ctf.example.com",
      "generic-hostname":"ctf.example.com",
      "default-server":"0",
      "deferred-server":"0",
      "tls-enabled":"1"
    },
    {
      "name":"ctf-hard-level",
      "target":"ctfd-ctf-hard-level-container",
      "internal-port":"8000",
      "description":"A CTF with a hard level",
      "hostname":"hard.ctf.example.com",
      "generic-hostname":"ctf.example.com",
      "default-server":"0",
      "deferred-server":"0",
      "tls-enabled":"1"
    }
  ],
  "tls":
  [
    {
      "hostnames":"ctf.example.com entry.ctf.example.com medium.ctf.example.com hard.ctf.example.com",
      "description":"This certificat can be used for all ctf.example.com subdomains",
      "email":"admin@example.com",
      "setup":"1"
    },
    {
      "hostnames":"ctf-2.example.com",
      "description":"This certificat can be used separetely for another CTF instances",
      "email":"admin@example.com",
      "setup":"1"
    }
  ],
  "common": {
    "tasks_compatible":"0",
    "proxy_conf_path":""
  }
}
```

### Configuration details

In this section, we will explain how each parameter works in the configuration file:

| Field | Description | Default |
|-------|-------------|---------|
| `projects` | Each object will describe a CTFd instance. If the element was newly added, a new CTFd instance will be created. If the element already existed, the existing CTFd instance will be modified. But actually if an element was removed, the existing CTFd instance will not be removed. In the previous example, we setup three CTFd instances. | `[]` |
| `projects[].name` | This is only an ID for the CTFd instance that should be uniq. The name will not be viewed in the browsed since it's referenced in the build process to generate the new CTFd instance. It should respect only the alpha-numeric notation with `"-"`, `"_"`, `"."` extra characters `[a-z-_\.]` (no uppercase characters will be allowed). It is important to note that no other extra characters was allowed. Otherwise, the build will crash. | "" |
| `projects[].description` | The description is not viewed anywhere. It's only for better understanding the configuration file, for which the CTFd instance was created. | "" |
| `projects[].hostname` | This is the real domain name that will publish the CTFd instance. If no domain name is available, just put the IP address. Please, note that if you use IP addresses instead of a domain name, you will use the ability of publishing multiple CTFd instances since this feature works with shared CTF instances on the same port using virtual hosts that only require a variable domain name (1 IP address, 1 port (80 for HTTP or 443 for HTTPS) and a lot of domain names). In the previous example, we generated 3 CTFd instances using the domain names `entry.ctf.example.com`, `medium.ctf.example.com` and `hard.ctf.example.com`. | "" |
| `projects[].generic-hostname` | This is the first domain name that was used to create a TLS certificate from the path `tls[].hostnames`. Because, for every `tls` element, a new TLS certificate will be created and it will get the name of the first domain name in the `tls[].hostnames` list. As you can see in the previous example, the second and the third `projects` elements have the same `projects[].generic-hostname` value which is `ctf.example.com` because the second and the third CTFd instances were using the same TLS certificate generated in `tls[0]` using the hostnames `ctf.example.com *.ctf.example.com` which confirms that the first element in this list is `ctf.example.com`. So basically, I think that the `tls[].hostnames` value should be a valid domain name with no wildcard. If the hostname will not have a TLS certificate, it will be useless to set this value since this value will be directly used to generate the TLS certificate (see the previous example). | "" |
| `projects[].tls-enabled` | This parameter will decide if TLS will be enabled (`projects[].tls-enabled` equals '1') so the CTFd instance will be published over HTTPS or if TLS will be disabled (`projects[].tls-enabled` equals '0') so the CTFd instance will be published over HTTP. In the previous example, we enabled TLS only for the second and the third instances. | "" |
| `projects[].target` | This is the Docker container name of CTFd that you can find when you execute `docker ps`. That will be the target of the traffic that comes to the reverse proxy and that will be routed to the CTFd instance to serve the HTTP(S) traffic. | `"ctfd"`+`projects[].name` |
| `projects[].internal-port` | This is the port of the CTFd web service that is running in `projects[].target` Docker container | `"8000"` |
| `tls` | Each object will describe a TLS certificate. If the element was newly added, a new TLS certificate will be created. If the element already existed, the existing TLS certificate will be modified. But actually if an element was removed, the existing TLS certificate will not be removed. In the previous example, we setup two TLS certificates. | `[]` |
| `tls[].hostnames` | In addition to what was previously described in `projects[].generic-hostname`, all these hostnames will be associated to only one TLS certificate. The hostnames are separeted with a single blank space (not more than one blank space). Wildcards '*' are allowed to include all subdomains but there is a problem: if you use wildcards, you have to change `authenticator = dns` in the `templates/letsencrypt-template.ini` file to propagate the configuration and you should perform a [DNS challenge](https://certbot.eff.org/docs/using.html?highlight=dns#dns-plugins) to create the TLS certificate successfully. So, using wildcards is not recommended, it's better to set all the subdomains in the same TLS certificate. | "" |
| `tls[].description` | The description is not viewed anywhere. It's only for better understanding the configuration file, for which the TLS certificate was created. | "" |
| `tls[].email` | Since Letsencrypt (certbot) require a valid email address to register your domains, you should not use a non-existing email or a temp-mail for avoiding security issues. | "" |
| `tls[].setup` | When you generate the CTFd instances the first time with their TLS certificate (using `tls[].setup` equals to '1'), you will certainly need to disable regenerating the TLS certificate that you just already generated when you were performing some edits to the configuration files and you needed to update the CTFd instances especially you will find that generating TLS certificates much time will make you spamming Letsencrypt (certbot) production servers and that could blacklist you for a while (maybe for one hour). So after generating TLS certificates the first time, you need to disable generating the already generated TLS certificates (`tls[].setup` equals to '0') | "" |

## How it works

After saving the `config.json`, you have to run the main script [0-all-setup.sh](0-all-setup.sh):

```
./0-all-setup.sh
```

This will create/edit all the CTFd instances and that will generate all the enabled TLS certificates (from the configuration file).

Every CTFd instance have three docker containers:

- `ctfd`

- `db`

- `cache`

And you will find a common docker container `proxy` shared with all the CTFd instances.

To check if everything was OK, you have to execute:

```
docker ps
```

For the previous example, you have to see ten docker containers: `proxy`, `ctfd_ctf-entry-level`, `db_ctf-entry-level`, `cache_ctf-entry-level`, `ctfd_ctf-medium-level`, `db_ctf-medium-level`, `cache_ctf-medium-level`, `ctfd_ctf-hard-level`, `db_ctf-hard-level`, `cache_ctf-hard-level`.

## Reporting an issue or a feature request

Issues and feature requests are tracked in the Github [issue tracker](https://github.com/mohamedaymenkarmous/multi-ctfd-docker-deploy/issues).

