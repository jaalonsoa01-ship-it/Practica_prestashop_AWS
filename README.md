# Configuración de la maquina virtual:

La maquina virtual que usara VirtualBox con 2 GB de RAM, con Ubuntuserver y al menos 20 GB de disco, un solo adaptador NAT con reenvio de puertos:

| prot  | p.anf | p.inv |
| --- | --- | --- |
| http  | 8080  | 80    |
| https | 8443  | 443   |
| ssh   | 2222  | 22    |

Requiero de un openssh, por lo tanto realizare la instalación de Ubuntu server 26.04 LTS de forma manual, una vez creados los scripts procedemos a cambiar los permisos, con el siguiente comando:

```chmod +x ~/practica_prestashop/scripts/*.sh```

# Pila lamp

```sudo ~/practica_prestashop/scripts/install_lamp.sh```

Una vez instalado apache, mysql, php y phpmyadmin; procedemos a instalar el certificado con el siguiente comando

```sudo ~/practica_prestashop/scripts/setup_letsencrypt_https.sh```

Finalizado la instalación del certificado, podemos abrir la página 

https://joaquinpreshop.duckdns.org:8443/phpmyadmin/index.php?route=/

Luego entonces, procederemos a instalar prestashop
 
```sudo ./scripts/deploy_prestashop.sh```

```sudo ~/practica_prestashop/scripts/deploy_prestashop.sh```

El resultado de este ultimo script es de

```
 ¡Despliegue completado con éxito!
 Tienda Front-Office: https://joaquinpreshop.duckdns.org:8443
 Panel Back-Office:   https://joaquinpreshop.duckdns.org:8443/admin_tienda
 Verificación PHP:    https://joaquinpreshop.duckdns.org:8443/phppsinfo.php
```
