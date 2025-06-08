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

## Workflows

1. **Validar Pull Request**
   
   Al crear una pull request se compila el código, se ejecutan tests y se analiza en SonarQube (si contiene código). Si, 
   además, la rama de destino es `main` y la pull request proviene de una rama `release` o `hotfix` se validarán los 
   elementos necesarios para hacer la release (fichero changelog, que la versión no exista, que no contenga 
   dependencias snapshot, ...).
    ```mermaid
    flowchart LR
        PR1(("pull_request"))
        subgraph SUB1 [ ]
            direction TB
            V1["Configurar maven *"]
            V2["Compilar código *"]
            V3["Ejecutar tests"]
            V4["Análisis SonarQube"]
            V5{"Si 
                destino 'main' y 
                origen 'release' 
                o 'hotfix'"}
            V6["Validar nueva versión"]
        end
        
        PR1 -- opened
               synchronize
               reopened --> SUB1
        V1 --> V2 --> V3 --> V4 --> V5 --> V6
    ```
   
2. **Crear Snapshot**

   Al hacer push a la rama `develop` se compila el código, se ejecutan tests, se valida la versión snapshot, se 
   elimina el snapshot antiguo si existe y se despliega la nueva snapshot.
    ```mermaid
    flowchart LR
        D1(("push"))
        subgraph SUB1 [ ]
            direction TB
            S1["Configurar maven *"]
            S2["Compilar código *"]
            S3["Ejecutar tests"]
            S4["Validar Snapshot"]
            S5["Eliminar Snapshot antiguo"]
            S6["Desplegar Snapshot"]
        end
        
        D1 -- develop --> SUB1
        S1 --> S2 --> S3 --> S4 --> S5 --> S6
    ```
   
3. **Preparar release**

   Al hacer push a la rama `develop`, si el último commit contiene `#ready` o mediante ejecución manual, se valida 
   la versión y se crea la correspondiente rama `release` a partir del código de `develop`.
    ```mermaid
    flowchart LR
        D1(("push"))
        D2(("workflow_dispatch"))
        subgraph SUB1 [ ]
            direction TB
            S1["Configurar maven *"]
            S2["Validar versión"]
            S3["Crear rama release"]
        end
    
        D1 -- develop 
              (commit #ready) --> SUB1
        D2 --> SUB1
        S1 --> S2 --> S3 
    ```
   
4. **Crear Pull Request**

   Al hacer push a una rama `release` o `hotfix`, si el último commit contiene `#ready` o mediante ejecución manual, 
   se prepara la nueva versión y se crea un pull request a `main`.
    ```mermaid
    flowchart LR
        D1(("push"))
        D2(("workflow_dispatch"))
        subgraph SUB1 [ ]
            direction TB
            S1["Configurar maven *"]
            S2["Preparar versión"]
            S3["Crear pull request"]
        end
    
        D1 -- release
              hotfix
              (commit #ready) --> SUB1
        D2 --> SUB1
        S1 --> S2 --> S3 
    ```
   
5. **Publicar Release**

   Tras fusionar un pull request de `release` o `hotfix` a `main`, despliega la versión final y crea un nuevo pull request 
   si es necesario.
    ```mermaid
    flowchart LR
        D1(("pull_request"))
        D2{"Si 
            destino 'main' y
            origen 'release'
            o 'hotfix'"}
        subgraph SUB1 [ ]
            direction TB
            S1["Configurar maven *"]
            S2["Desplegar Release"]
            S3["Crear nueva Release"]
        end
    
        D1 -- closed
              merged --> D2 --> SUB1
        S1 --> S2 --> S3 
    ```
   
6. **Iniciar Hotfix**

   Permite iniciar un `hotfix` manualmente, validando y preparando la versión, y creando la rama de `hotfix` 
   correspondiente.
    ```mermaid
    flowchart LR
        D1(("workflow_dispatch"))
        subgraph SUB1 [ ]
            direction TB
            S1["Validar versión"]
            S2["Preparar versión"]
            S3["Crear rama hotfix"]
        end
        
        D1 --> SUB1
        S1 --> S2 --> S3
    ```

(*): cacheable