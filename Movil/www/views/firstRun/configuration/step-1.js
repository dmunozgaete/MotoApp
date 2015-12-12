angular.route('nomenu.firstRun/configuration/step-1', function(
    $scope,
    $state,
    $log,
    $Api,
    $Configuration,
    $cordovaDialogs,
    $cordovaContacts,
    $Identity,
    $ionicLoading,
    $LocalStorage
)
{

    //---------------------------------------------------
    // Model
    $scope.collections = $Configuration.get("collections");

    $scope.data = {
        emergencyPhones: []
    };

    //------------------------------------------------
    // Action's
    $scope.save = function(data)
    {
        $ionicLoading.show(
        {
            template: 'Actualizando...'
        });


        $Api.update("/Accounts/Me", data)
            .success(function(response)
            {

                //Extend the identity to add personal data
                $Identity.extend("personal", data);

                //Set user personal data!
                var label = $Configuration.get("localstorageStamps").personal_data;
                var userData = $LocalStorage.setObject(label, data);

                //Set Profile
                $state.go("app.home");

                $ionicLoading.hide();

            })
            .error(function()
            {

                $ionicLoading.show(
                {
                    template: 'No logramos guardar la información, por lo que volveremos a pedirla mas adelante',
                    duration: 6000
                });

                //Set Profile
                $state.go("app.home");

            });

    };

    $scope.delete = function(item, index)
    {

        $cordovaDialogs.confirm('¿Desea elminar este contacto?', 'Remover Contacto', ['Cancelar', 'Remover'])
            .then(function(buttonIndex)
            {
                if (buttonIndex == 2)
                {
                    $scope.data.emergencyPhones.splice(index, 1);
                }
            });


        return false;
    };

    $scope.pickContact = function()
    {
        $cordovaContacts.pickContact()
            .then(function(contactPicked)
            {
                if (contactPicked.phoneNumbers && contactPicked.phoneNumbers.length > 0)
                {
                    var phone = contactPicked.phoneNumbers[0].value;

                    $scope.data.emergencyPhones.push(
                        phone
                    );
                }

            });

    };

});
