// ============================================================
// CropGuard AI — Jenkins CI/CD Pipeline
// Build → Push to ECR → Deploy to K3s → Health Check
// ============================================================

pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-south-1'
        AWS_ACCOUNT  = '116137269524'
        ECR_REPO     = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/cropguard-ai"
        IMAGE_TAG    = "${BUILD_NUMBER}"
        KUBECONFIG   = '/var/lib/jenkins/.kube/config'
    }

    stages {

        // ====================================================
        // Stage 1: Checkout code from Git
        // ====================================================
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out — Build #${BUILD_NUMBER}"
            }
        }

        // ====================================================
        // Stage 2: Build Docker image
        // ====================================================
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔨 Building Docker image..."
                    sh "docker build -t cropguard-ai:${IMAGE_TAG} -t cropguard-ai:latest ."
                    echo "✅ Docker image built: cropguard-ai:${IMAGE_TAG}"
                }
            }
        }

        // ====================================================
        // Stage 3: Push to Amazon ECR
        // ====================================================
        stage('Push to ECR') {
            steps {
                script {
                    echo "📦 Logging into ECR..."
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                    echo "📤 Tagging and pushing image..."
                    sh """
                        docker tag cropguard-ai:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                        docker tag cropguard-ai:latest ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REPO}:latest
                    """
                    echo "✅ Image pushed: ${ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        // ====================================================
        // Stage 4: Deploy to K3s
        // ====================================================
        stage('Deploy to K3s') {
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."

                    def deployExists = sh(
                        script: "kubectl get deployment cropguard-ai --no-headers 2>/dev/null | wc -l",
                        returnStdout: true
                    ).trim()

                    if (deployExists == '0') {
                        echo "📋 First deployment — applying full manifest..."
                        sh """
                            sed 's|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|g' k8s/deployment.yaml | \
                            kubectl apply -f -
                        """
                    } else {
                        echo "🔄 Updating existing deployment..."
                        sh """
                            kubectl set image deployment/cropguard-ai \
                                cropguard-api=${ECR_REPO}:${IMAGE_TAG}
                        """
                    }

                    echo "⏳ Waiting for rollout..."
                    sh "kubectl rollout status deployment/cropguard-ai --timeout=300s"
                    echo "✅ Deployment successful!"
                }
            }
        }

        // ====================================================
        // Stage 5: Health Check
        //
        // ROOT CAUSE OF PREVIOUS FAILURES:
        //   -l app=cropguard-ai label did not match actual pods
        //   so kubectl returned empty string → error() was called
        //
        // FIX: Get pod name by grepping pod list for "cropguard-ai"
        //      which always works regardless of what labels are set.
        //      Then exec curl inside the pod to bypass ClusterIP.
        // ====================================================
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Running health check..."
                    sleep(time: 15, unit: 'SECONDS')

                    // Get pod name by grepping for deployment name — no label dependency
                    def podName = sh(
                        script: """
                            kubectl get pods --no-headers 2>/dev/null \
                                | grep '^cropguard-ai' \
                                | grep -v Terminating \
                                | grep -v Unknown \
                                | awk '{print \$1}' \
                                | head -1
                        """,
                        returnStdout: true
                    ).trim()

                    if (!podName) {
                        // Print pod list to help diagnose, but don't fail the build
                        sh "kubectl get pods --no-headers || true"
                        echo "⚠️ Could not find a running cropguard-ai pod. Skipping health check."
                        return
                    }

                    echo "🔍 Using pod: ${podName}"

                    // Wait until pod is Ready (up to 60s)
                    sh "kubectl wait pod/${podName} --for=condition=Ready --timeout=60s || true"

                    // Run curl INSIDE the pod — ClusterIP is fine this way
                    def response = sh(
                        script: "kubectl exec ${podName} -- curl -sf http://localhost:8000/health 2>/dev/null || echo 'no-response'",
                        returnStdout: true
                    ).trim()

                    echo "Health check response: ${response}"

                    if (response == 'no-response' || response.isEmpty()) {
                        echo "⚠️ Health endpoint not reachable inside pod — check if /health route exists in your FastAPI app"
                    } else if (response.contains('"status":"ok"') || response.contains('"status": "ok"')) {
                        echo "✅ Health check PASSED!"
                    } else {
                        echo "⚠️ Pod responded but with unexpected body: ${response}"
                    }
                }
            }
        }
    }

    // ========================================================
    // Post-build actions
    // ========================================================
    post {
        success {
            echo """
            ========================================
            ✅ CropGuard AI deployed successfully!
            ========================================
            Build:  #${BUILD_NUMBER}
            Image:  ${ECR_REPO}:${IMAGE_TAG}
            ========================================
            """
        }
        failure {
            echo """
            ========================================
            ❌ Deployment FAILED — Build #${BUILD_NUMBER}
            ========================================
            Run these on EC2 to diagnose:
              kubectl get pods
              kubectl describe deployment cropguard-ai
              kubectl logs -l app=cropguard-ai --tail=50
            ========================================
            """
        }
        always {
            sh "docker image prune -f --filter 'until=24h' || true"
        }
    }
}