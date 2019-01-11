import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/colors.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/kalium_icons.dart';
import 'package:kalium_wallet_flutter/model/authentication_method.dart';
import 'package:kalium_wallet_flutter/model/available_currency.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/ui/settings/backupseed_sheet.dart';
import 'package:kalium_wallet_flutter/ui/settings/changerepresentative_sheet.dart';
import 'package:kalium_wallet_flutter/ui/settings/settings_list_item.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/widgets/security.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/util/biometrics.dart';

class SettingsSheet extends StatefulWidget {
  _SettingsSheetState createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _hasBiometrics = false;
  AuthenticationMethod _curAuthMethod =
      AuthenticationMethod(AuthMethod.BIOMETRICS);
  AvailableCurrency _curCurrency =
      AvailableCurrency(AvailableCurrencyEnum.USD); // TODO use device locale

  void pinEnteredTest(String pin) {
    print("Pin Entered $pin");
  }

  @override
  void initState() {
    super.initState();
    // Determine if they have face or fingerprint enrolled, if not hide the setting
    BiometricUtil.hasBiometrics().then((bool hasBiometrics) {
      setState(() {
        _hasBiometrics = hasBiometrics;
      });
    });
    SharedPrefsUtil.inst.getAuthMethod().then((authMethod) {
      setState(() {
        _curAuthMethod = authMethod;
      });
    });
    SharedPrefsUtil.inst.getCurrency().then((currency) {
      setState(() {
        _curCurrency = currency;
      });
    });
  }

  Future<void> _authMethodDialog() async {
    switch (await showDialog<AuthMethod>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text(
              "Authentication Method",
              style: KaliumStyles.TextStyleDialogHeader,
            ),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AuthMethod.PIN);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text(
                    'PIN',
                    style: KaliumStyles.TextStyleDialogOptions,
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AuthMethod.BIOMETRICS);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text(
                    'Biometrics',
                    style: KaliumStyles.TextStyleDialogOptions,
                  ),
                ),
              ),
            ],
          );
        })) {
      case AuthMethod.PIN:
        SharedPrefsUtil.inst
            .setAuthMethod(AuthenticationMethod(AuthMethod.PIN))
            .then((result) {
          setState(() {
            _curAuthMethod = AuthenticationMethod(AuthMethod.PIN);
          });
        });
        break;
      case AuthMethod.BIOMETRICS:
        SharedPrefsUtil.inst
            .setAuthMethod(AuthenticationMethod(AuthMethod.BIOMETRICS))
            .then((result) {
          setState(() {
            _curAuthMethod = AuthenticationMethod(AuthMethod.BIOMETRICS);
          });
        });
        break;
    }
  }

  List<Widget> _buildCurrencyOptions() {
    List<Widget> ret = new List();
    AvailableCurrencyEnum.values.forEach((AvailableCurrencyEnum value) {
      ret.add(SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AvailableCurrency(value).getDisplayName(),
                    style: KaliumStyles.TextStyleDialogOptions,
                  ),
                ),
              )
      );
    });
    return ret;
  }  

  Future<void> _currencyDialog() async {
    AvailableCurrencyEnum selection = await showDialog<AvailableCurrencyEnum>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom:10.0),
              child: const Text(
                "Change Currency",
                style: KaliumStyles.TextStyleDialogHeader,
              ),
            ),
            children: _buildCurrencyOptions(),
          );
        });
    SharedPrefsUtil.inst.setCurrency(AvailableCurrency(selection)).then((result) {
      if (_curCurrency.currency != selection) {
        setState(() {
          _curCurrency = AvailableCurrency(selection);
        });
        StateContainer.of(context).requestSubscribe();
      }
    });
  }

  bool notNull(Object o) => o != null;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: KaliumColors.backgroundDark,
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 30.0, top: 60.0, bottom: 10.0),
            child: Row(
              children: <Widget>[
                Text("Settings", style: KaliumStyles.TextStyleHeader),
              ],
            ),
          ),
          Expanded(
              child: Stack(
            children: <Widget>[
              ListView(
                padding: EdgeInsets.only(top: 15.0),
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 30.0, bottom: 10),
                    child: Text("Preferences",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w100,
                            color: KaliumColors.text60)),
                  ),
                  Divider(height: 2),
                  KaliumSettings.buildSettingsListItemDoubleLine('Change Currency',
                      _curCurrency, KaliumIcons.currency, _currencyDialog),
                  Divider(height: 2),
                  buildSettingsListItemDoubleLine(
                      'Language', 'System Default', KaliumIcons.language),
                  Divider(height: 2),
                  _hasBiometrics
                      ? KaliumSettings.buildSettingsListItemDoubleLine(
                          "Authentication Method",
                          _curAuthMethod,
                          KaliumIcons.fingerprint,
                          _authMethodDialog)
                      : null,
                  Divider(height: 2),
                  buildSettingsListItemDoubleLine(
                      'Notifications', 'On', KaliumIcons.notifications),
                  Divider(height: 2),
                  Container(
                    margin:
                        EdgeInsets.only(left: 30.0, top: 20.0, bottom: 10.0),
                    child: Text("Manage",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w100,
                            color: KaliumColors.text60)),
                  ),
                  Divider(height: 2),
                  buildSettingsListItemSingleLine(
                      'Contacts', KaliumIcons.contacts),
                  Divider(height: 2),
                  buildSettingsListItemSingleLine(
                      'Backup Seed', KaliumIcons.backupseed, onPressed: () {
                    // Authenticate
                    SharedPrefsUtil.inst.getAuthMethod().then((authMethod) {
                      BiometricUtil.hasBiometrics().then((hasBiometrics) {
                        if (authMethod.method == AuthMethod.BIOMETRICS &&
                            hasBiometrics) {
                          BiometricUtil.authenticateWithBiometrics(
                                  "Backup Seed")
                              .then((authenticated) {
                            if (authenticated) {
                              new KaliumSeedBackupSheet()
                                  .mainBottomSheet(context);
                            }
                          });
                        } else {
                          // PIN Authentication
                          Vault.inst.getPin().then((expectedPin) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                              return new PinScreen(
                                PinOverlayType.ENTER_PIN,
                                (pin) => new KaliumSeedBackupSheet()
                                    .mainBottomSheet(context),
                                expectedPin: expectedPin,
                                description: "Enter PIN to backup seed",
                              );
                            }));
                          });
                        }
                      });
                    });
                  }),
                  Divider(height: 2),
                  buildSettingsListItemSingleLine(
                      'Load from Paper Wallet', KaliumIcons.transferfunds,
                      onPressed: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return new PinScreen(
                          PinOverlayType.NEW_PIN, pinEnteredTest);
                    }));
                  }),
                  Divider(height: 2),
                  buildSettingsListItemSingleLine(
                      'Change Representative', KaliumIcons.changerepresentative,
                      onPressed: () {
                    new KaliumChangeRepresentativeSheet()
                        .mainBottomSheet(context);
                  }),
                  Divider(height: 2),
                  buildSettingsListItemSingleLine('Logout', KaliumIcons.logout,
                      onPressed: () {
                    KaliumDialogs.showConfirmDialog(
                        context,
                        "WARNING",
                        "Logging out will remove your seed and all Kalium-related data from this device. If your seed is not backed up, you will never be able to access your funds again",
                        "DELETE SEED AND LOGOUT", () {
                      // Show another confirm dialog
                      KaliumDialogs.showConfirmDialog(
                          context,
                          "Are you sure?",
                          "As long as you've backed up your seed you have nothing to worry about.",
                          "YES", () {
                        Vault.inst.deleteAll().then((Null) {
                          SharedPrefsUtil.inst.deleteAll().then((result) {
                            StateContainer.of(context).logOut();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/', (Route<dynamic> route) => false);
                          });
                        });
                      });
                    });
                  }),
                  Divider(height: 2),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text("KaliumF v0.1",
                            style: KaliumStyles.TextStyleVersion),
                      ],
                    ),
                  ),
                ].where(notNull).toList(),
              ),
              //List Top Gradient End
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 20.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KaliumColors.backgroundDark,
                        KaliumColors.backgroundDark00
                      ],
                      begin: Alignment(0.5, -1.0),
                      end: Alignment(0.5, 1.0),
                    ),
                  ),
                ),
              ), //List Top Gradient End
            ],
          )),
        ],
      ),
    );
  }
}
