/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Share Dialog Controller , to publish the route
------------------------------------------------------*/
(function()
{
    var closureContext = null;
    var result = null;
    var closureModal = null;

    //MODAL DIALOG (SHARE)
    angular.module('app.controllers')
        .controller('ShareDialogController', function(
            $scope,
            $state,
            $log,
            $ionicModal
        )
        {
            $scope.data = angular.copy(closureContext,
            {});

            //-------------------------------------------
            // Model
            $scope.share = function()
            {
                result = $scope.data;
                closureModal.remove();
            };

            $scope.cancel = function()
            {
                result = null;
                closureModal.remove();
            };

        });

    // SERVICE
    angular.module("app.services")
        .provider('ShareDialog', function()
        {
            var $ref = this;

            this.$get = function($log, $q, $ionicModal)
            {
                var self = {};

                //ADD NEW FACTORY
                self.share = function(context)
                {
                    var defer = $q.defer();
                    closureContext = context;

                    //SHOW DIALOG
                    $ionicModal.fromTemplateUrl('views/routes/create/dialogs/share.html',
                    {
                        animation: 'slide-in-up',
                        backdropClickToClose: true,
                        focusFirstInput: true
                    }).then(function(modalDialog)
                    {
                        closureModal = modalDialog;
                        closureModal.show();

                        // Execute action on hide modal
                        closureModal.scope.$on('modal.hidden', function()
                        {
                            //CANCEL
                            if (!result)
                            {
                                defer.reject(result);
                            }
                            else
                            {
                                //SAVE
                                defer.resolve(result);
                            }

                        });


                    });


                    return defer.promise;
                };

                return self;
            };
        });
})();
