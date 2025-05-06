# wakamiti-github-actions

Un repositorio centralizado de GitHub Actions reutilizables diseñadas para agilizar y automatizar flujos de trabajo 
para proyectos impulsados por Wakamiti. Este repositorio proporciona acciones modulares para tareas comunes, 
asegurando consistencia y eficiencia a través de los repositorios.


## Acciones Disponibles

### 1. Validate
Ejecuta comprobaciones de validación en el proyecto, como linting, formateo o verificación de esquemas.

_Ejemplo:_
```yaml
uses: wakamiti/wakamiti-github-actions/.github/workflows/validate.yml@main
secrets: inherit
```

### 2. Snapshot
Maneja el despliegue de versiones snapshot de proyectos Wakamiti al repositorio de paquetes de Github.

_Ejemplo:_
```yaml
uses: wakamiti/wakamiti-github-actions/.github/workflows/snapshot.yml@main
secrets: inherit
```

Automatiza la creación de versiones, incluyendo el etiquetado de versiones y la generación de changelogs.
1. Crea una rama `release` para la nueva versión.
2. Etiqueta los pom y el changelog con la nueva versión.
3. Crea un pull request a `main` desde la rama `release`.

_Ejemplo:_
```yaml
uses: wakamiti/wakamiti-github-actions/.github/workflows/release.yml@main
secrets: inherit
```

## Pruebas

Para ejecutar pruebas de las GitHub Actions localmente, se utiliza la herramienta [act](https://github.com/nektos/act). 
Esta herramienta permite simular la ejecución de flujos de trabajo de GitHub Actions en tu máquina local, facilitando 
la depuración y validación.

### Configuración

1. Instalar `act` siguiendo las instrucciones de su [documentación oficial](https://nektosact.com/installation/index.html).
2. Asegúrate de tener Docker instalado y en ejecución, ya que `act` utiliza contenedores para simular los flujos de 
   trabajo.

> [!TIP]
> Para instalar `act` en Windows, se recomienda usar [chocolatey](https://docs.chocolatey.org/en-us/choco/setup/)


### Comandos Disponibles

- **Instalar dependencias**:
  ```shell
  make install
  ```

- **Ejecutar pruebas**:
  ```shell
  make test
  ```

- **Limpiar el entorno**:
  ```shell
  make clean
  ```

- **Actualizar workflows**:
  ```shell
  make workflows
  ```

