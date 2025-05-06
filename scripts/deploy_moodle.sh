
#!/bin/bash

# Configuramos para mostrar los comandos y finalizar si hay error
set -ex

# Importamos el archivo de variables
source .env

# Creamos  la base de datos de usuario
mysql -u root <<< "DROP DATABASE IF EXISTS $moodle_DB_NAME"
mysql -u root <<< "CREATE DATABASE $moodle_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $moodle_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $moodle_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$moodle_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $moodle_DB_NAME.* TO $moodle_DB_USER@$IP_CLIENTE_MYSQL"


#Eliminamos el moodle antiguo
rm -rf moodle

#Clonamos el repositorio del moodle a nuestra maquina ubuntu

git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git

#Quitamos lo que hay en html
rm -rf /var/www/html/*

# Movemos el contenido de moodle a la carpeta de html
mv moodle/* /var/www/html/

#Borramos la carpeta moodle de la carpeta scripts
rm -rf moodle

#Ponemos permisos de root a la carpeta de moodle
chown -R root /var/www/html/
chmod -R 0755 /var/www/html/

#Borramos la carpeta antigua
rm -rf /var/www/moodledata

#Creamos una carpeta moodledata
mkdir /var/www/moodledata

# Le ponemos permisos
chown -R www-data:www-data /var/www/moodledata

#Movemos el htaccess a la carpeta de moodledata

cp ../htaccess/.htaccess /var/www/moodledata/

#Cambiamos el numero maximo de variables permitidas a 5000
sed -i "s/;max_input_vars = 1000/max_input_vars = 5000/" /etc/php/8.3/cli/php.ini

# Una vez configurado todos los parametros instalamos en automatico el moodle
php $moodle_DIRECTORY/admin/cli/install.php \
    --wwwroot="https://$LE_DOMAIN" \
    --dataroot=/var/www/moodledata \
    --dbname=$moodle_DB_NAME \
    --dbuser=$moodle_DB_USER \
    --dbpass=$moodle_DB_PASSWORD \
    --dbhost=$IP_CLIENTE_MYSQL \
    --fullname="$FullName" \
    --shortname=$ShorName \
    --adminuser=$AdminUser \
    --adminpass=$AdminPass \
    --non-interactive \
    --agree-license \
    --lang=es

# Cambiamos para que los demas puedan ver la pagina
chmod -R 755 /var/www/html
 
# Reiniciamos el apache
systemctl restart apache2
