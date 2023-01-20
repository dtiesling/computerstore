# The Computer Store
## View the live deployment [here](https://computerstore.danieltiesling.com/computerstore).

## Application Architecture
The web application consists of a Next.js app for the frontend and a Django app for the REST API backend. Both
apps are run on the same domain behind an Nginx server that handles routing requests to the correct app. This is all 
bundled in a Docker container with a single entrypoint that becomes a standalone stateless instance of the web application. 
This removes the complexity of having the REST API on a separate domain as well as reducing the total number of different
workloads that need to be run. In a production setting, running at a large scale, there would be a point where this setup 
would be too inefficient and these services would need to be split up.

I chose Next.js for the frontend because the application is an e-commerce site and the pre-rendering would be a boon for 
SEO. It also seemed like a great excuse for me to learn Next.js. I did not get far enough in the docs to dig into the 
pre-rendering side, so I can assume I am not using it to its full potential. Overall I enjoyed working with Next.js and it 
was able to deliver on the spec, so I'm happy. You'll notice there is an extra page when you hit the 

The data loading portion is easy to miss. I opted for a [data migration](./django_app/computers/migrations/0003_add_base_inventory.py) 
in Django instead of a script to load the data. This purely to ease development and testing since it gave me a fully loaded
DB each time I ran the migrations.


## Deployment Infrastructure
- Web application is deployed in Elastic Container Service (ECS) as a Fargate service.
- Web application containers run in ECS are stored in the Elastic Container Registry (ECR).
- PostgreSQL database is hosted in RDS
- DNS is managed in Route 53 and sends requests from clients to an Application Load Balancer that routes to a healthy instance of the web application in ECS.
- All resources are managed using Terraform.

## Improvements to make before going to production
As I was working on this example I had to make most decisions in respect to time. Below is the list of the ideal
list of changes I would make before going into production. In the real world it's unlikely doing all of this would be 
possible, at least not in the first iteration. This is also not an exhaustive list of things that could be improved but 
those that came to mind while working on this.

### Infrastructure
- Potentially scrap ECS altogether in favor of Kubernetes depending on requirements and plans for the future.
- Tighten up IAM policies used by services. They are over-privileged currently.
- Provision a standard secure networking setup. Currently running on all default networking with virtually no rules.
  - Private subnet for services with NAT gateway to public subnet
  - Separate security groups for services with appropriate ingress and egress rules
- Auto-scaling
- Store terraform state remotely in S3 or terraform cloud.
- Tune database parameters
- Provision elasticsearch instance and sync data. Use to drive search bar.
- Store/retrieve DB passwords Secrets Manager instead of env vars in task definitions
- Add layers in front of Application Load Balancer for performance and security (CDN, WAF, DDoS Protection, etc.). I'm a fan of Cloudflare but AWS has all the equivalent tooling.
- SIEM (i.e. Splunk or DataDog)
- Error monitoring (i.e. Sentry or similar)
- Overall Monitoring/Observability tools (i.e. Datadog or AWS equivalent toolset)
- Add failover support for RDS database. Currently only a single instance is provisioned.
- Depending on user base may need to start looking at having infrastructure in multiple regions/continents.
- Make sure all services are HA.
- Enable backups on RDS database and test disaster recovery process.

### Code
- Security pass on the frontend code. There are some high severity vulnerabilities in dependencies.
- Lots more tests.
- Break terraform code into modules. Single main.tf file is already getting large.
- Vendor should be its own table and Computer should foreign key to it.
- Backend logging (general info logs as needed and audit logging for security/compliance).
- Type-hinting in Python.
- Convert frontend code to Typescript.
- Documentation (code, quick start instructions and local dev environment setup)
- Make frontend responsive.
- May need to address when database migrations are done once we scale to multiple instances since they are run on server start.
- Frontend error handling.
- Reduce docker image bloat. Could be using build stages to remove unneeded files.

### CI/CD
- Implement git flow - deploy to dev, stage/QA and prod environments on commit to correlated branches.
- Unit/integration testing checks before merging code.
- SAST & DAST checks before merging code.
- Code linter/auto-formatter on commit.
- Code test coverage limit checks before merging code.
- Build and push containers to registry automatically.
- Set up terraform cloud to test and deploy infrastructure changes on commit.
