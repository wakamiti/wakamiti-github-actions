#!/bin/bash

mkdir -p /etc/gitlab/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/gitlab/ssl/gitlab.key -out /etc/gitlab/ssl/gitlab.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=MiEmpresa/OU=IT/CN=localhost"

/assets/init-container &
while ! curl -sSf http://localhost/users/sign_in > /dev/null 2>&1; do sleep 10; done

# Configurar usuario administrador y token
gitlab-rails runner "
begin
  user = User.new(
    username: 'tester',
    email: 'tester@example.com',
    name: 'Tester',
    password: 'xK9#mP2@',
    password_confirmation: 'xK9#mP2@'
  )
  user.assign_personal_namespace(Organizations::Organization.default_organization)
  user.skip_confirmation!
  user.admin = true
  if user.save
      token = PersonalAccessToken.create!(
        user: user,
        name: 'API Token',
        scopes: ['api', 'write_repository'],
        expires_at: 365.days.from_now
      )
      puts token.token
    else
      STDERR.puts \"Error al crear usuario: #{user.errors.full_messages.join(', ')}\"
      exit 1
    end
rescue => e
  STDERR.puts 'Error: ' + e.message
  exit 1
end" 1> /root/token

# Configurar Git global
git config --global user.name "tester"
git config --global user.email "tester@example.com"
git config --global --add safe.directory "*"
git config --global credential.helper store
#git config --global url."https://".insteadOf git://

# Configurar credenciales HTTPS
#echo "http://tester:xK9#mP2@@localhost" > /root/.git-credentials
#chmod 600 /root/.git-credentials

echo "Inicialización de GitLab completada"
wait