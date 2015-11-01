
TMP_FILE='unused_sg.txt'

comm -23  <(aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId'  --output text | tr '\t' '\n'| sort) <(aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text | tr '\t' '\n' | sort | uniq) > $TMP_FILE

while read sg 
do
    echo "Delete $sg"
    aws ec2 delete-security-group --group-id $sg
done < $TMP_FILE
