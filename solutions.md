# Part A — Bug tickets

## RES-101 · Search shows results for the wrong query

### Time Spent: ~1 hour

### Root Cause
When user type on TextField, it trigger `TextField.onChanged` and it create new request everytime user typing new value. That make request that take longer to get response can replace matched query results.

### Solution
In `search_deals_controller.dart`, I add debounce timer and wrap around `_search()` method to only start new request when it necessary. And I add search id for tracking latest query request and only let latest request update results and update screen to not make old request overwrite newer results.

## RES-102 · Crash after leaving My orders

### Time Spent: ~10 mins

### Root Cause
In `PickupCountdown` widget, inside `initState()` there is a timer that keep running and update state. And when user close "My orders" page but timer don't get cancel. it will cause a "setState() after dispose" error.

### Solution
Make sure timer got dispose by created new variable that store that timer and inside `dispose()` method, then call `_timer?.cancel()` to stop timer from running. and for safety, I add `mounted` condition check to prevent widget to call setState even if the widget is disposed.