#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {
  if [[ $1 ]]
    then
      echo -e "\n$1 What would you like today?\n"
    else
     echo -e "\nWelcome to My Salon, how can I help you?\n"
  fi
  SERVICES=$($PSQL "SELECT service_id, name FROM services")
  echo -e "$SERVICES" | while IFS="|" read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  CHOOSE_SERVICE
}

CHOOSE_SERVICE() {
  read SERVICE_ID_SELECTED

  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "'$SERVICE_ID_SELECTED' is not a number."
  else
    SERVICE_ID_QUERY_RESULT=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")

    if [[ -z $SERVICE_ID_QUERY_RESULT ]]
    then
      MAIN_MENU "I could not find that service."
    else
      echo -e "What's your phone number?"
      read CUSTOMER_PHONE

      CUSTOMER_ID_QUERY_RESULT=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      if [[ -z $CUSTOMER_ID_QUERY_RESULT ]]
      then
        CREATE_CUSTOMER $CUSTOMER_PHONE
        NEW_CUSTOMER_ID_QUERY_RESULT=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
        BOOK_SERVICE $NEW_CUSTOMER_ID_QUERY_RESULT $SERVICE_ID_QUERY_RESULT
      else
        BOOK_SERVICE $CUSTOMER_ID_QUERY_RESULT $SERVICE_ID_QUERY_RESULT
      fi
    fi
  fi
}

CREATE_CUSTOMER() {
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  INSERT_CUSTOMERS_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$1')")
  NEW_CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$1'")
}

BOOK_SERVICE() {
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$1")
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$2")

  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  if [[ -z $SERVICE_TIME ]]
  then
    MAIN_MENU "You didn't inclide appointment time. Plaese retry."
  else
    INSERT_INTO_APPOINTMENTS_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($1, $2, '$SERVICE_TIME')")

    if [[ $INSERT_INTO_APPOINTMENTS_RESULT ]]
    then
      echo -e "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

MAIN_MENU
