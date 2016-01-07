angular.module("app")
    .directive('sportSelector', function()
    {
        return {
            restrict: 'E',
            scope:  
            {
                onComplete: '&' //Complete Step
            },
            templateUrl: 'views/firstRun/configure/directives/sportSelector.html',
            controller: function($scope, SportDialog, $Identity, $Configuration, $LocalStorage)
            {

                // Select Function 
                $scope.select = function()
                {
                    SportDialog.show(
                    {
                        emergencyPhones: []
                    }).then(function(data)
                    {

                        //Extend the identity to add personal data
                        $Identity.extend("personal", data);

                        //Set user personal data!
                        var label = $Configuration.get("localstorageStamps").personal_data;
                        $LocalStorage.setObject(label, data);

                        //Trigger to parent scope  
                        $scope.onComplete();
                    });

                };

            }
        };
    });
