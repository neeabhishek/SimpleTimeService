#Base image for reducing the size.
FROM python:3.11-alpine
#Working directory for the application.
WORKDIR /app

#Group (with GID 1001) and User (with UID 1001) creation to avoid running the application as a root user.
RUN addgroup --gid 1001 appadmingroup && \
    adduser --uid 1001 --ingroup appadmingroup --home /home/appadmin --disabled-password appadmin && \
    chown -R appadmin:appadmingroup /app

#Installing the required packages for the application.
#Deleting .whl related cache from source.
COPY SimpleTimeService/requirement.txt /app
RUN pip install --no-cache-dir -r requirement.txt && \
    rm -rf /root/.cache/pip && \
    rm -rf /root/.local/share/pip

#Dumping the source code to the container layer.
COPY SimpleTimeService/app.py /app

#Switch to non-root user and start the application.
USER appadmin
EXPOSE 5000
CMD ["python3","app.py"]