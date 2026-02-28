# Configuration for Helm Templates

This document explains how to configure **VS Code** for working with **Helm templates** that use YAML files.

## 1. Treat `.yaml` and `.tpl` files as Helm

Add the following to your VS Code `settings.json` to let VS Code recognize Helm templates:


```json
"files.associations": {
  "**/templates/*.yaml": "helm",
  "**/templates/*.tpl": "helm"
}
```
* `**/templates/*.yaml` – Treats all `.yaml` files inside `templates` folders as Helm files.
* `**/templates/*.tpl` – Treats all `.tpl` files inside `templates` folders as Helm files.

## 2. Disable strict YAML validation

Helm templates use Go templating syntax like `{{ }}`, which can trigger YAML validation errors. To avoid this, add:

```json
"yaml.validate": false
```

This disables strict YAML validation so you can work with Helm templates without warnings.

---
