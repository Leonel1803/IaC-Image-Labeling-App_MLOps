# PRD + Architecture Spec

## Proyecto: Serverless Image Labeling Pipeline

---

# 1. Resumen

Construir un pipeline event-driven que:

1. Reciba imágenes en S3
2. Dispare Lambda automáticamente al subirlas
3. Use Rekognition para detectar etiquetas
4. Guarde metadata e índices por etiquetas en DynamoDB
5. Permita consultas posteriores por etiquetas

Meta:

```text
Subir imagen -> etiquetar automáticamente -> consultar imágenes por labels
```

---

# 2. Problema

Hoy las imágenes son blobs mudos.

Queremos volverlas consultables por semántica:

```text
dame imágenes con:
- dog
- beach
- person
```

Sin etiquetado manual.

---

# 3. Objetivos

## Functional Goals

Debe permitir:

* Upload de imágenes
* Auto labeling
* Persistencia de labels
* Búsqueda por etiqueta
* Consultas futuras por múltiples etiquetas

---

## Non Functional Goals

* Serverless
* Bajo costo
* Escalable
* Event-driven
* Infra como código
* Seguridad por defecto

---

# 4. Fuera de scope (por ahora)

NO incluye:

* thumbnails
* procesamiento de imágenes
* edición
* embeddings / vector search
* similitud visual
* moderación de contenido
* UI frontend

No construir un mini Google Photos todavía.

---

# 5. Arquitectura

```text
Client
  ↓
S3 bucket
  ↓ ObjectCreated
Lambda
  ↓
Rekognition DetectLabels
  ↓
DynamoDB
```

---

## Servicios AWS

Usar:

* Amazon S3
* AWS Lambda
* Amazon Rekognition
* Amazon DynamoDB

---

# 6. Diseño S3

## Bucket requirements

```yaml
private: true
encryption: SSE-S3
versioning: enabled
public_access: blocked
prefix: images/
lifecycle:
  30_days -> Standard-IA
```

## Object naming

```text
images/{uuid}.jpg
```

No nombres humanos.

---

## S3 Event

Trigger:

```text
ObjectCreated
Prefix: images/
```

Dispara Lambda.

Opcional futuro:

```text
ObjectRemoved
```

para limpiar índices.

---

# 7. DynamoDB Data Model

Single-table design.

Tabla:

```text
ImageIndex
```

---

## Tipo A: Imagen metadata

```json
PK: IMAGE#<id>
SK: METADATA

{
 imageId,
 s3Key,
 labels[],
 uploadedAt
}
```

---

## Tipo B: Label inverted index

```json
PK: LABEL#Dog
SK: IMAGE#123
```

Una fila por etiqueta.

Ejemplo:

```text
LABEL#Dog     IMAGE#123
LABEL#Beach   IMAGE#123
LABEL#Animal  IMAGE#123
```

---

## Queries soportadas

### Obtener imagen

```text
PK=IMAGE#123
```

---

### Buscar por etiqueta

```text
PK=LABEL#Dog
```

---

### Dog + Beach

Intersección en aplicación.

---

## No hacer

No guardar:

```json
Dog: [10000 imágenes]
```

Anti-pattern.

---

# 8. Lambda Responsibilities

Lambda debe:

1. Obtener bucket y key del evento
2. Llamar:

```python
rekognition.detect_labels()
```

3. Filtrar labels

Ejemplo:

```text
confidence > 90
```

4. Guardar metadata
5. Crear items por etiqueta en Dynamo

---

## Pseudocode

```python
receive s3 event

extract key

labels = rekognition.detect_labels()

save image metadata

for label in labels:
   save label index
```

---

# 9. Seguridad

Lambda IAM:

Solo:

```text
s3:GetObject
rekognition:DetectLabels
dynamodb:PutItem
dynamodb:BatchWriteItem
```

Least privilege.

---

# 10. Terraform Architecture

Usar Terraform.

Estructura:

```text
repo/

modules/
  s3/
  lambda/
  dynamodb/
  iam/

envs/
  dev/
  prod/
```

---

## Root

Root solo orquesta módulos.

```hcl
module "s3" {}

module "lambda" {}

module "dynamodb" {}

module "iam" {}
```

---

# 11. Terraform State

Usar remote state después:

S3 backend:

```hcl
backend "s3" {
 ...
}
```

Locking:

DynamoDB.

---

# 12. Acceptance Criteria

## Upload

Cuando se sube imagen:

```text
se ejecuta Lambda automáticamente
```

---

## Labeling

Para una imagen:

```text
dog_on_beach.jpg
```

debe guardar:

```text
Dog
Beach
Animal
```

---

## Query

Buscar:

```text
Dog
```

retorna imágenes asociadas.

---

# 13 Riesgos

## Riesgo: Hot partitions

Ejemplo:

```text
LABEL#Person
```

millones de registros.

Mitigación futura:

sharding.

---

## Riesgo: Etiquetas basura

Mitigación:

confidence threshold.

---

## Riesgo: Delete inconsistency

Mitigación:

ObjectRemoved handler.

---

# 14 Fases de implementación

## Fase 1

Infra base

* bucket
* dynamo
* iam
* terraform

---

## Fase 2

Lambda + Rekognition

---

## Fase 3

Label indexing

---

## Fase 4

Queries

---

# 15 Tareas para Codex

## Epic 1 Terraform

Generar:

```text
modules/s3
modules/lambda
modules/dynamodb
modules/iam
```

Tasks:

* crear módulo s3
* agregar encryption
* event notification
* dynamodb table
* lambda role

---

## Epic 2 Lambda

Generar Python:

* handler
* Rekognition integration
* Dynamo writes
* error handling
* retries

---

## Epic 3 Testing

Crear:

* unit tests
* integration tests
* mock s3 events

---

## Epic 4 Documentation

Generar:

```text
README
Architecture diagram
Deployment guide
```

---

# 16 Prompt para Codex

Usa esto como prompt inicial:

```text
Actúa como senior cloud architect y pair programmer.

Implementa este proyecto iterativamente.

Orden:
1 diseñar repo
2 generar terraform modules
3 generar lambda python
4 conectar dynamodb indexing
5 cuestionar decisiones de arquitectura
6 proponer mejoras y edge cases

Reglas:
- usar Terraform
- modular
- production minded
- explicar decisiones
- evitar overengineering
```

---

# 17 Futuro (v2)

Posibles extensiones:

* multi-label search optimization
* vector search
* image similarity
* moderation
* OpenSearch
* embeddings

---

## Repo target final

```text
image-label-pipeline/
 ├── modules/
 │    ├── s3
 │    ├── lambda
 │    ├── dynamodb
 │    └── iam
 ├── envs/
 │    └── dev
 ├── lambda/
 └── docs/
```

---

## Preguntas que Codex debe desafiar

Debe cuestionar:

* ¿Single table o dos tablas?
* ¿Sharding por labels?
* ¿S3 direct trigger o EventBridge + SQS?
* ¿Confidence thresholds?
* ¿Delete consistency?

No solo generar código.
También cuestionar decisiones.

---

# 18 Backlog inicial sugerido (opcional)

## Sprint 1

* Terraform módulo S3
* Terraform módulo DynamoDB
* Terraform módulo IAM
* Deploy entorno dev

## Sprint 2

* Lambda mínima que procese evento
* Integración Rekognition
* Persistencia en DynamoDB

## Sprint 3

* Queries por etiquetas
* Manejo de deletes
* Tests e integración

---

# 19 Definition of Done

Una historia está terminada si:

* Infra deployable vía Terraform
* Lambda procesando imágenes correctamente
* Labels persistidas en DynamoDB
* Query por etiqueta funcionando
* Tests pasando
* README actualizado
* IaC reproducible desde cero

---

# 20 Comprobación de Funcionamiento

* Levantamos un servidor local (python -m http.server 5500)
* Nos dirigimos a http://localhost:5500/web/
* Subimos una imagen
* Hacemos la busqueda relacionada con esa imagen

Fin del documento.
