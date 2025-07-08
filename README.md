# wakamiti-github-actions

Un repositorio centralizado de workflows reutilizables diseñados para agilizar y automatizar flujos de trabajo 
para proyectos impulsados por Wakamiti. Este repositorio proporciona acciones modulares para tareas comunes, 
asegurando consistencia y eficiencia a través de los repositorios.


## Workflows

1. **Validar Código**

   Este workflow se activa al crear una pull request. Valida el código mediante compilación, ejecución de tests y 
   análisis en SonarQube. Si la rama de destino es `main` y la pull request proviene de una rama `release` o 
   `hotfix`, también valida los elementos necesarios para hacer la release (fichero changelog, que la versión no 
   exista, que no contenga dependencias snapshot, ...).
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

   Este workflow se activa al hacer push a la rama `develop`. Se compila el código, se ejecutan tests, se valida la 
   versión snapshot, se elimina el snapshot antiguo si existe y se despliega la nueva snapshot.
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

3. **Preparar Release**

   Este workflow se activa al hacer push a la rama `develop` con un commit que contiene `#ready` o mediante 
   ejecución manual. Valida la versión y se crea la correspondiente rama `release` a partir del código de `develop`.
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

   Este workflow se activa al hacer push a una rama `release` o `hotfix` o mediante ejecución manual. Prepara la 
   nueva versión y se crea un pull request a `main`.
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

   Este workflow se activa cuando se cierra y fusiona un pull request desde una rama `release` o `hotfix` a la rama 
   `main` o mediante  ejecución manual. Despliega la versión final y crea una release en GitHub.
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

   Este workflow es una variante del workflow "Preparar Release" que se activa manualmente para crear una rama de hotfix
   a partir de la rama `main`. Validan y prepara la versión, y creando la rama de `hotfix` correspondiente.
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

7. **Rebase Ramas**
   
   Este workflow se activa al hacer push a la rama `main`. Se encarga de hacer rebase de las ramas `develop`, 
   `release` y `hotfix` sobre la rama `main`.
   ```mermaid
     flowchart LR
         PUSH(("push"))
         subgraph SUB1[ ]
            direction TB
            V1["Rebase ramas"]
         end
      
         PUSH -- main --> SUB1
   ```

(*): cacheable


## Pruebas

Para ejecutar pruebas de las GitHub Actions localmente, se utiliza la herramienta [act](https://github.com/nektos/act). 
Esta herramienta permite simular la ejecución de flujos de trabajo de GitHub Actions en tu máquina local, facilitando 
la depuración y validación. Esta herramienta ha sido dockerizada, junto con una serie de servicios simulados.

> [!IMPORTANT]
> Es necesario poder conectarse a Git mediante clave pública SSH. 
> [Ver más](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

### Comandos Disponibles

- **Instalar dependencias**:
  ```shell
  make install
  ```

- **Ejecutar pruebas**:
  ```shell
  make test
  ```

- **Limpiar pruebas**:
  
  Elimina los repositorios de las pruebas en el servidor git simulado.
  ```shell
  make clean
  ```

- **Actualizar workflows**:
  
  Carga los workflows en el contenedor de `act`.
  ```shell
  make workflows
  ```

- **Limpiar entorno**:

  Elimina las carpetas `target` y el contenedor de `act`.
  ```shell
  make shutdown
  ```