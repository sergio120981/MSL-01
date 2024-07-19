region=AFECTED_REGION
profile=AWS_PROFILE
aws --profile=$profile ecs list-clusters --region=$region --output text | awk '{print $2}'  > "clusters-$region.txt"
while IFS= read -r cluster; do 
  service=$(aws --profile=$profile ecs list-services --region=$region --cluster=$cluster --output text | awk '{print $2}')
  # in this case just one service per ECS, if more that 1 service then LOOP
  aws --profile=$profile ecs delete-service --force --region=$region --cluster=$cluster --service=$service 1>/dev/null
  # end of LOOP
  aws --profile=$profile ecs delete-cluster --region=$region --cluster=$cluster 1>/dev/null
done < "clusters-$region.txt"
