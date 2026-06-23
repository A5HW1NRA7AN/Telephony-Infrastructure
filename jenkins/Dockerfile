FROM jenkins/jenkins:lts-jdk17

# Skip initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Copy plugins definition
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Run jenkins-plugin-cli to pre-install plugins during docker build
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
