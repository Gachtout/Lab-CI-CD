# Image de base épinglée par digest : le tag indique la version, le digest garantit le contenu.
FROM public.ecr.aws/docker/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Le digest fige aussi les failles connues de l'image de base : on applique les
# correctifs de sécurité publiés depuis sa construction.
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
# pip ne sert qu'à l'installation : on le retire ensuite, avec les bibliothèques qu'il embarque.
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall --yes pip

COPY app.py .

# Utilisateur non privilégié, identifiant numérique fixe
RUN useradd --system --uid 10001 --no-create-home appuser
USER 10001

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"]

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
