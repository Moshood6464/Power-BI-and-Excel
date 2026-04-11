use filtyvile;
describe people;
--  1. Crime Reports that occur on july 28, 2021
  select * from crime_scene_reports where year = 2021 and month = 7 and day =28 and street = 'Humphrey Street';
  -- 2. Find all people who live on Humphrey Street
   select name, people.name, people.license_plate,
    bakery_security_logs.activity from people
     join bakery_security_logs
     on people.license_plate = bakery_security_logs.license_plate
     where bakery_security_logs.year=2021
     and bakery_security_logs.month = 7
     and bakery_security_logs.day = 28
     and bakery_security_logs.hour = 10;
 -- 4. List all interviews conducted on the same day as the crime
      select name, transcript from interviews
       where year = 2021 and month = 7 and day = 28;
-- 5. Find all flights departing from fiftyville airport on that day
       select * from flights where origin_airport_id = (select id from airports where city = 'filtyvile')
        and year = 2021 and month = 7 and day = 28;
 -- INTERMEDIATE  LEVEL
 -- 1. FIND THE NAMES OF PEOPLE WHO MADE  ATM WITHDRAWALS ON THE DAY OF CRIME
    select name from people
    join bank_accounts on people.id = bank_accounts.person_id
    join atm_transactions on bank_accounts.account_number = atm_transactions .account_number
     where year = 2021 and month = 7 and day = 28 and atm_location ='Leggett street' and transaction_type = 'withdraw';
     -- 2. LIST ALL  PHONE CALLS  MADE ON THAT DAY THAT LASTED LESS THAN 60 SECONDS 
           select * from phone_calls where year = 2021 and month = 7 and day = 28 and duration < 60; 
		-- 3. IDENTIFY ALL PASSENGERS ON FLIGHTS LEAVING FIFTYVILLE ON JULY 29,2021
             select name from people
              join passengers on
              people.passport_number = passengers.passport_number where flight_id in (
               select id from flights where year = 2021 and month = 7 and day = 29
               and origin_airport_id = (select id from airports where city = 'filtyvile')
               );
		-- 4.  FIND PEOPLE WHO WHERE INTERVIEWED AND ALSO APPEAR IN THE PEOPLE TABLE
                select name from people where name in (select name from interviews where year = 2021 and month = 7 and day = 28);
	    -- 5.  SHOW ALL BANK ACCOUNTS LINKED TO PEOPLE WHO MADE ATM WITHDRAWALS THAT DAY
               select account_number, person_id from bank_accounts
                where account_number in (
                select account_number from atm_transactions where year = 2021 and month = 7 and day = 28
                );
			-- ADVANCED LEVEL 
     -- 1. identify people who made a withdrawal and a short phone call
       select name from people
	    join bank_accounts on people.id = bank_accounts.person_id
        join atm_transactions on bank_accounts . account_number = atm_transactions.account_number
        where atm_transactions . year = 2021 and atm_transactions .month = 7 and atm_transactions .day = 28
        and people.phone_number in (select caller from phone_calls where year = 2021 and month = 7 and day = 28 and duration < 60
        );
        --  Find the suspects who left fiftyville on july 29 on the earliest flight
             select name from people
			-- 1. Must be a passenger on the earliest flight out of fiftyville on july 29
               join passengers on
               people.passport_number=
               passengers.passport_number
               where passengers .flight_id = (
               select id from flights where year = 2021 and month = 7 and day = 29 and origin_airport_id =(select id
               from airports where city = 'filtyvile') order by hour, minute
               limit 1
                )
                -- 2. Must have made an ATM withdrawals on the day of the crime (July 28)
				 and people.id in (
                 select person_id from bank_accounts
                 join atm_transactions on bank_accounts.account_number =atm_transactions.account_number 
                 where year = 2021 and month = 7 and day = 28 and atm_location =  'Leggett Street'
                 and transaction_type = 'withdraw'
                 )
			-- 3. Must have made a phone call lasting for 60 seconds on the day of crime
               and people.phone_number in (
               select caller
               from phone_calls where year = 2021 and month = 7 and day = 28
                and duration < 60
                );
			-- 3. Identify the earliest flight leaving fiftyville on July 29
              select flights.id,hour, minute,
               destination_airport_id from flights
               join airports on
               flights.origin_airport_id = airports .id
               where city = 'filtyvile' and year = 2021 and month = 7 and day = 29
               order by hour, minute limit 1;
			-- 4. Find all passengers on that earliest flight
                 select name  from people
                 join passengers on
                 people.passport_number =
                 passengers.passport_number
                 where flight_id = (
                 select id from flights where year = 2021 and month = 7 and day = 29
                 order by hour, minute limit 1
                 );
				-- 5. Combine clues  to find the prime suspects
                 select name from people
			-- 1. Exited the bakery parking lot within 10 mins of the crime (10:15am - 10:25am)
                join bakery_security_logs
                on people.license_plate = bakery_security_logs.license_plate
			-- 2. Withdrew money at Leggett street ATM
               join bank_accounts on people.id =
               bank_accounts .person_id 
               join atm_transactions on
               bank_accounts.account_number =
               atm_transactions.account_number
		  -- 3.  Took the earliest flight out the next day
          join passengers on
          people.passport_number=
          passengers.passport_number
          where bakery_security_logs.year=2021
          and bakery_security_logs.month =7
          and bakery_security_logs .day = 28
          and bakery_security_logs.hour = 10
          and bakery_security_logs .minute >= 15
          and bakery_security_logs .minute <= 25
          and bakery_security_logs .activity = 'exit'
          and atm_transactions.year = 2021
          and atm_transactions.month = 7
          and atm_transactions.day = 28
          and atm_transactions.atm_location = 'Leggett street'  
          and atm_transactions.transaction_type = 'withdraw'
	-- 4. Made a 60 seconds phone call 
         and people.phone_number in (
         select caller from phone_calls where year = 2021 and month = 7 and day = 28
         and duration < 60
         )
 -- Filter for the earliest flight departures on July 29
  and passengers.flight_id =(
  select id from flights where year = 2021 and month = 7 and day = 29
  and origin_airport_id =(select id from airports where city = 'filtyvile')
  order by hour, minute
  limit 1
  );
  -- ADVANCED LEVEL
  -- 1.  Who committed the crime?
    -- By intersecting all the clues (Bakery logs, ATM, Phone and Flight), the data revelas: Who committed the crime?
    -- Reasoning: His license Plate was seen leaving the bakery, he made a withdrawal, he was the caller on a short phone call and he was on the earliest flight
     -- 2. Where did they escape to?
     -- New York City 
     -- Reasoning : This was the destination of the earliest flight (ID 36) on July 29th
     -- 3. Who was  their accomplice?
     -- Reasoning: Robin was the person Bruce called for less than 60 seconds right after the crime to book the flight
     
  
         
          
          
          
          
            
            
			