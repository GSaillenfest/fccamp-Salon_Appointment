#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n -~-~-~- Welcome to the salon -~-~-~-\n"


SERVICE_MENU () {
  if [[ $1 ]]
  then
    echo -e " - - - \n$1\n - - - "
  fi

  echo -e "\nPlease chose your service:"
  
  SERVICES_LIST=$($PSQL "SELECT * FROM services")
  echo "$SERVICES_LIST" | while read SERVICE_ID BAR NAME
    do
      echo "$SERVICE_ID) $NAME"
    done
  read SERVICE_ID_SELECTED
  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    #query service_id 
    SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    #if does not exist
    if [[ -z $SERVICE_ID ]]
    then  
      #send back to main menu
      SERVICE_MENU "No service found, please select a valid number"
    #else
    else
      #select service
      #call reservation function
      RESERVATION $SERVICE_ID
    fi
  #else
  else
    #send back to main menu
    SERVICE_MENU "Please enter a valid number"
  fi
}

RESERVATION () {

  SERVICE_ID=$1
  echo -e "\nPlease enter your phone number:"
  read CUSTOMER_PHONE
  #Query customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  #if not found
  if [[ -z $CUSTOMER_ID ]]
  then
    #read name
    echo -e "\nPlease enter your name:"
    read CUSTOMER_NAME
    #register customer
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    if [[ $INSERT_CUSTOMER_RESULT == 'INSERT 0 1' ]]
    then
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    else
      echo "An error occured, please enter a shorter name" 
      RESERVATION $SERVICE_ID 
    fi
  fi
  #ask time
  echo -e "\nPlease enter the hour of appointment (HH:MM):"
  read SERVICE_TIME
  #register appointment
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")
  if [[ $INSERT_APPOINTMENT_RESULT == 'INSERT 0 1' ]]
  then
    APPOINTMENT_INFO=$($PSQL "SELECT services.name, customers.name, time FROM appointments INNER JOIN customers USING(customer_id) INNER JOIN services USING(service_id) WHERE customer_id=$CUSTOMER_ID AND time='$SERVICE_TIME'")
    APPOINTMENT_INFO_FORMATTED=$(echo $APPOINTMENT_INFO | sed 's/ *([a-z]*) */1/g')
    echo $APPOINTMENT_INFO | while IFS='|' read SERVICE NAME TIME
    do
    FORMATTED_SERVICE=$(echo $SERVICE | sed 's/^ | $//g')
    FORMATTED_NAME=$(echo $NAME | sed 's/^ | $//g')
    FORMATTED_TIME=$(echo $TIME | sed 's/^ | $//g')
      echo "I have put you down for a $FORMATTED_SERVICE at $FORMATTED_TIME, $FORMATTED_NAME."
    done
  else
     echo "An error occured, please try again"
     RESERVATION $SERVICE_ID
  fi
}

SERVICE_MENU