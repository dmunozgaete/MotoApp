/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Rewards Modal controller
 Github:            http://ngcordova.com/docs/plugins/geolocation/
------------------------------------------------------*/
(function()
{
    var closureScope = null;
    var modal = null;

    //MODAL DIALOG (REWARDS)
    angular.module('app.controllers')
        .controller('RewardDialogController', function(
            $scope,
            $state,
            $log,
            $timeout,
            $ionicModal
        )
        {
            $scope.data = closureScope.medals[0];

            //-------------------------------------------
            // Model
            $scope.close = function()
            {

                modal.remove();

                //-------------------------------------------
                //RAISE NEW LEVEL???
                if (closureScope.details.level.up)
                {
                    var delay = $timeout(function(){

                        //SHOW NEW LEVEL PANEL
                        $ionicModal.fromTemplateUrl('views/rewards/raiseLevel.html',
                        {
                            animation: 'slide-in-up'
                        }).then(function(modalDialog)
                        {
                            modal = modalDialog;
                            modal.show();
                        });

                        $timeout.cancel(delay);

                    }, 500);
                }
                //-------------------------------------------
            };

        });

    //MODAL DIALOG (RAISE LEVEL)
    angular.module('app.controllers')
        .controller('RaiseLevelDialogController', function(
            $scope,
            $state,
            $log
        )
        {

            $scope.data = closureScope.details;

            //-------------------------------------------
            // Model
            $scope.close = function()
            {
                modal.remove();
            };

        });

    // SERVICE
    angular.module("app.services")
        .provider('Rewards', function()
        {
            var $ref = this;

            this.$get = function(
                $log,
                $q,
                BaseEventHandler,
                $Api,
                $ionicModal
            )
            {
                var self = {};

                //ADD NEW FACTORY
                self.check = function(category)
                {

                    //CHECK REWARDS! (CATEGORIZED)
                    $Api.read("/Accounts/Me/NewMedals/{category}",
                        {
                            category: category
                        })
                        .success(function(rewards)
                        {
                            $log.info(rewards);
                            //------------------------------------------------
                            //USER HAS WINNING SOMETHING???
                            if (rewards.medals.length > 0)
                            {
                                closureScope = rewards;

                                //SHOW REWARD PANE
                                $ionicModal.fromTemplateUrl('views/rewards/reward.html',
                                {
                                    animation: 'slide-in-up'
                                }).then(function(modalDialog)
                                {
                                    modal = modalDialog;
                                    modal.show();
                                });

                            };
                            //------------------------------------------------

                        });

                };

                return self;
            };
        });
})();
