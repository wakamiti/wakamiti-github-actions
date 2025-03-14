# wakamiti-github-actions

Un repositorio centralizado de GitHub Actions reutilizables diseñadas para agilizar y automatizar flujos de trabajo 
para proyectos impulsados por Wakamiti. Este repositorio proporciona acciones modulares para tareas comunes, 
asegurando consistencia y eficiencia a través de los repositorios.

## Acciones Disponibles

### 1. Validate
Ejecuta comprobaciones de validación en el proyecto, como linting, formateo o verificación de esquemas.

_Ejemplo:_
```yaml
uses: wakamiti/wakamiti-github-actions/actions/validate.yml@main
with:
  repo: ${{ github.event.repository.name }}
secrets: inherit
```

### 2. Snapshot
Maneja el despliegue de versiones snapshot de proyectos Wakamiti al repositorio de paquetes de Github.

_Ejemplo:_
```yaml
uses: wakamiti/wakamiti-github-actions/actions/snapshot.yml@main
secrets: inherit
```


## Primeros pasos
Añade la acción deseada al fichero de flujo de trabajo de GitHub:

```yaml
name: Example Workflow
on:
  push:
    branches:
      - main
jobs:
  validate:
    runs-on: ubuntu-latest
    uses: wakamiti/wakamiti-github-actions/actions/validate.yml@main
    with:
      repo: ${{ github.event.repository.name }}
    secrets: inherit
```
